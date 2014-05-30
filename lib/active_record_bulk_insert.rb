ActiveRecord::Base.class_eval do
  def self.bulk_insert_in_batches(attrs, options = {})
    batch_size = options.fetch(:batch_size, 1000)

    attrs.each_slice(batch_size).map do |sliced_attrs|
      bulk_insert(sliced_attrs, options)
    end.flatten.compact
  end

  def self.bulk_insert(attrs, options = {})
    use_provided_primary_key = options.fetch(:use_provided_primary_key, false)
    attributes = _resolve_record(attrs.first, use_provided_primary_key).keys.join(", ")

    if options.fetch(:validate, false)
      attrs, invalid = attrs.partition { |record| _validate(record) }
    end

    values_sql = attrs.map do |record|
      "(#{_resolve_record(record, use_provided_primary_key).values.map { |r| sanitize(r) }.join(', ')})"
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

  def self._resolve_record(record, use_provided_primary_key)
    if record.is_a?(Hash) && use_provided_primary_key
      record.except(primary_key).except(primary_key.to_sym)
    elsif record.is_a?(Hash)
      record
    elsif record.is_a?(ActiveRecord::Base) && use_provided_primary_key
      record.attributes
    elsif record.is_a?(ActiveRecord::Base)
      record.attributes.except(primary_key).except(primary_key.to_sym)
    end
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
