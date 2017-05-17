ActiveRecord::Base.class_eval do
  def self.bulk_insert_in_batches(attrs, options = {})
    batch_size = options.fetch(:batch_size, 1000)
    delay      = options.fetch(:delay, nil)

    invalid = []
    attrs.each_slice(batch_size) do |sliced_attrs|
      invalid += bulk_insert(sliced_attrs, options)
      sleep(delay) if delay
    end
    invalid
  end

  def self.bulk_insert(attrs, options = {})
    return [] if attrs.empty?

    use_provided_primary_key = options.fetch(:use_provided_primary_key, false)
    attributes = _resolve_record(attrs.first, options).keys.join(", ")

    invalid = []
    if options.fetch(:validate, false) || options.fetch(:validate_with, false)
      _validator = options.fetch(:validate_with, self.method(:_validate))
      attrs, invalid = attrs.partition { |record| _validator.call(record) }
    end

    values_sql = attrs.map do |record|
      quoted = _resolve_record(record, options).map {|k, v|
        _bulk_insert_quote(k, v)
      }
      "(#{quoted.join(', ')})"
    end.join(",")

    sql = <<-SQL
      INSERT INTO #{quoted_table_name}
        (#{attributes})
      VALUES
        #{values_sql}
    SQL
    connection.execute(sql) unless attrs.empty?
    invalid
  end

  def self._bulk_insert_quote(key, value)
    case ActiveRecord::VERSION::MAJOR
    when 5
      column = try(:column_for_attribute, key)
      value = connection.type_cast_from_column(column, value) if column
      connection.quote(value)
    when 4
      column = try(:column_for_attribute, key)
      connection.quote(value, column)
    else
      sanitize(value)
    end
  end

  def self._resolve_record(record, options)
    time = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now
    _record = record.is_a?(ActiveRecord::Base) ? record.attributes : record
    _record.merge!("created_at" => time, "updated_at" => time) unless options.fetch(:disable_timestamps, false)
    _record = _record.except(primary_key).except(primary_key.to_sym) unless options.fetch(:use_provided_primary_key, false)
    _record
  end

  def self._validate(record)
    if record.is_a?(Hash)
      new(record).valid?
    elsif record.is_a?(ActiveRecord::Base)
      record.valid?
    else
      false
    end
  end
end
