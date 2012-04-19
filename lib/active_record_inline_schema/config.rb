require 'set'
require 'lock_method'

class ActiveRecordInlineSchema::Config
  DEFAULT_CREATE_TABLE_OPTIONS = {
    :mysql => 'ENGINE=InnoDB'
  }

  attr_reader :model
  attr_reader :ideal_columns
  attr_reader :ideal_indexes

  def initialize(model)
    @model = model
    @ideal_columns = ::Set.new
    @ideal_indexes = ::Set.new
  end

  def add_ideal_column(column_name, options)
    ideal_columns.add Column.new(self, column_name, options)
  end

  def add_ideal_index(column_name, options)
    ideal_indexes.add Index.new(self, column_name, options)
  end

  def apply(create_table_options)
    non_standard_primary_key = if (primary_key_column = find_ideal_column(model.primary_key))
      primary_key_column.type != :primary_key
    end

    unless non_standard_primary_key
      add_ideal_column :id, :type => :primary_key
    end

    # Table doesn't exist, create it
    unless connection.table_exists? model.table_name

      if mysql?
        create_table_options ||= DEFAULT_CREATE_TABLE_OPTIONS[database_type]
      end

      table_definition = ::ActiveRecord::ConnectionAdapters::TableDefinition.new connection
      ideal_columns.each do |ideal_column|
        ideal_column.inject table_definition
      end

      # avoid using connection.create_table because in 3.0.x it ignores table_definition
      # and it also is too eager about adding a primary key column
      create_sql = "CREATE TABLE #{model.quoted_table_name} (#{table_definition.to_sql}) #{create_table_options}"

      if sqlite?
        connection.execute create_sql
        if non_standard_primary_key
          add_ideal_index model.primary_key, :unique => true
        end
      elsif postgresql?
        connection.execute create_sql
        if non_standard_primary_key
          # can't use add_index method because it won't let you do "PRIMARY KEY"
          connection.execute "ALTER TABLE #{model.quoted_table_name} ADD PRIMARY KEY (#{model.quoted_primary_key})"
        end
      elsif mysql?
        if non_standard_primary_key
          # only string keys are supported
          create_sql.sub! %r{#{connection.quote_column_name(model.primary_key)} varchar\(255\)([^,\)]*)}, "#{connection.quote_column_name(model.primary_key)} varchar(255)\\1 PRIMARY KEY"
          create_sql.sub! 'DEFAULT NULLPRIMARY KEY', 'PRIMARY KEY'
        end
        connection.execute create_sql
      end
      safe_reset_column_information
    end

    # Add to schema inheritance column if necessary
    if model.descendants.any? and not find_ideal_column(model.inheritance_column)
      add_ideal_column model.inheritance_column, :type => :string
    end

    # Remove fields from db no longer in schema
    existing_column_names.reject do |existing_column_name|
      find_ideal_column existing_column_name
    end.each do |existing_column_name|
      connection.remove_column model.table_name, existing_column_name
    end

    # Add fields to db new to schema
    ideal_columns.reject do |ideal_column|
      find_existing_column ideal_column.name
    end.each do |ideal_column|
      connection.add_column model.table_name, ideal_column.name, ideal_column.type, ideal_column.options
    end

    # Change attributes of existent columns
    existing_columns_hash.each do |existing_column_name, existing_column|
      next if existing_column_name.to_s == model.primary_key.to_s
      ideal_column = find_ideal_column existing_column_name
      option_changes = {}

      # First, check if the field type changed
      type_changed = !([existing_column.type.to_s, existing_column.sql_type.to_s].include?(ideal_column.type.to_s))

      # Next, iterate through our extended attributes, looking for any differences
      # This catches stuff like :null, :precision, etc
      ideal_column.options.except(:base).each do |k, v|
        if !v.nil? and v != existing_column.send(k)
          option_changes[k] = v
        end
      end

      # Change the column if applicable
      if type_changed or option_changes.any?
        connection.change_column model.table_name, existing_column_name, ideal_column.type, option_changes
      end
    end

    # Remove old index
    existing_index_names.reject do |existing_index_name|
      find_ideal_index existing_index_name
    end.each do |existing_index_name|
      connection.remove_index model.table_name, :name => existing_index_name
    end

    # Add indexes
    ideal_indexes.reject do |ideal_index|
      find_existing_index ideal_index.name
    end.each do |ideal_index|
      connection.add_index model.table_name, ideal_index.column_name, ideal_index.options
    end

    safe_reset_column_information
  end
  lock_method :apply, :ttl => 60

  def as_lock
    if connection.respond_to?(:current_database)
      [connection.current_database, model.name]
    else
      model.name
    end
  end

  def clear
    @ideal_columns = ::Set.new
    @ideal_indexes = ::Set.new
  end
  lock_method :clear, :ttl => 60

  private

  def find_ideal_column(name)
    ideal_columns.detect { |ideal_column| ideal_column.name.to_s == name.to_s }
  end

  def find_existing_column(name)
    existing_column_names.detect { |existing_column_name| existing_column_name.to_s == name.to_s }
  end

  def find_ideal_index(name)
    ideal_indexes.detect { |ideal_index| ideal_index.name.to_s == name.to_s }
  end

  def find_existing_index(name)
    existing_index_names.detect { |existing_index_name| existing_index_name.to_s == name.to_s }
  end

  def safe_reset_column_information
    if connection.respond_to?(:schema_cache)
      connection.schema_cache.clear!
    end
    model.reset_column_information
    model.descendants.each do |descendant|
      descendant.reset_column_information
    end
  end

  def existing_index_names
    safe_reset_column_information
    connection.indexes(model.table_name).map(&:name)
  end

  def existing_column_names
    safe_reset_column_information
    model.column_names
  end

  def existing_columns_hash
    safe_reset_column_information
    model.columns_hash
  end

  def connection
    unless model.connection.active?
      raise ::RuntimeError, %{[active_record_inline_schema] Must connect to database before running ActiveRecord::Base.auto_upgrade!}
    end
    model.connection
  end

  def database_type
    if mysql?
      :mysql
    elsif postgresql?
      :postgresql
    elsif sqlite?
      :sqlite
    end
  end

  def sqlite?
    connection.adapter_name =~ /sqlite/i
  end

  def mysql?
    connection.adapter_name =~ /mysql/i
  end

  def postgresql?
    connection.adapter_name =~ /postgresql/i
  end
end
