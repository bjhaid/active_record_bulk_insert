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


    to_import = columns
    to_import = to_import.reject { |column| column.name == primary_key } unless options.fetch(:use_provided_primary_key, false)

    invalid = []
    if options.fetch(:validate, false)
      attrs, invalid = attrs.partition { |record| _validate(record) }
    end

    values_sql = attrs.map do |record|
      attributes = _resolve_record(record, options)
      quoted = to_import.map { |column|
        k = column.name
        v = attributes[k] || attributes[k.to_sym]
        v = connection.type_cast_from_column(column, v)
        connection.quote(v)
      }
      "(#{quoted.join(', ')})"
    end.join(",")

    sql = <<-SQL
      INSERT INTO #{quoted_table_name}
        (#{to_import.map(&:name).join(", ")})
      VALUES
        #{values_sql}
    SQL
    connection.execute(sql) unless attrs.empty?
    invalid
  end

  def self._resolve_record(record, options)
     time = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now
    _record = record.is_a?(ActiveRecord::Base) ? record.attributes : record
    _record.merge!("created_at" => time, "updated_at" => time) unless options.fetch(:disable_timestamps, false)
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
