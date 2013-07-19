require 'set'
require 'logger'

class ActiveRecordInlineSchema::Config
  extend Memoist

  attr_reader :model, :ideal_columns, :ideal_indexes
  attr_accessor :dry_run

  def initialize(model)
    @model = model
    @ideal_columns = ::Set.new
    @ideal_indexes = ::Set.new
    @dry_run = false
  end

  def add_ideal_column(column_name, options)
    ideal_columns.add Column.new(self, column_name, options)
  end

  def add_ideal_index(column_name, options)
    ideal_indexes.add Index.new(self, column_name, options)
  end

  def log_dry(msg)
    (ActiveRecord::Base.logger || (@logger ||= Logger.new($stderr))).info "[ActiveRecordInlineSchema DRY RUN] #{msg}"
  end

  def apply(options)
    self.dry_run = options.fetch(:dry_run, false)
    ensure_primary_key_exists
    calculate_columns_for_table
    create_table_if_non_existent
    ensure_existence_of_non_standard_keys if sqlite?
    remove_non_existent_fields
    add_new_fields
    change_field_types
    remove_non_existent_indexes
    safe_reset_column_information
  end

  private

  def primary_key_column
    find_ideal_column(model.primary_key)
  end
  memoize :primary_key_column

  def has_primary_key?
    !model.primary_key ? false : true
  end
  memoize :has_primary_key?

  def non_standard_primary_key?
    if pkc = primary_key_column
      pkc.type != :primary_key
    elsif model.primary_key != 'id'
      true
    else
      false
    end
  end
  memoize :non_standard_primary_key?

  def table_definition
    if ActiveRecord::VERSION::MAJOR == 3
      ActiveRecord::ConnectionAdapters::TableDefinition.new connection
    else
      ActiveRecord::ConnectionAdapters::TableDefinition.new(
        model.connection.native_database_types, model.table_name, false, {}
      )
    end
  end
  memoize :table_definition

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
    model.connection
  end

  def database_type
    @database_type ||= if mysql?
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
    connection.adapter_name =~ /postgres/i
  end

  def ensure_primary_key_exists
    if non_standard_primary_key?
      if primary_key_column and (postgresql? or sqlite?)
        primary_key_column.options[:null] = false
      end
    elsif has_primary_key?
      add_ideal_column :id, :type => :primary_key
    end
  end

  def calculate_columns_for_table
    ideal_columns.each do |ideal_column|
      ideal_column.inject table_definition
    end
  end

  def create_table_if_non_existent
    unless connection.table_exists? model.table_name
      if ActiveRecord::VERSION::MAJOR > 3
        model.connection.class.const_get(:SchemaCreation).new(model.connection).accept table_definition
      else
        statements = []
        statements << "CREATE TABLE #{model.quoted_table_name} (#{table_definition.to_sql}) #{options[:create_table]}"

        if non_standard_primary_key?
          if postgresql?
            statements << %{ALTER TABLE #{model.quoted_table_name} ADD PRIMARY KEY (#{model.quoted_primary_key})}
          elsif mysql?
            k = model.quoted_primary_key
            statements.first.sub! /#{k}([^\)]+)\)([^\),]*)/, "#{k}\\1) PRIMARY KEY"
          end
        end

        statements.each do |sql|
          if dry_run
            log_dry sql
          else
            connection.execute sql
          end
        end
      end
      safe_reset_column_information
    end
  end

  def ensure_existence_of_non_standard_keys
    if non_standard_primary_key?
      # make sure this doesn't get deleted later
      add_ideal_index model.primary_key, :unique => true
    end
  end

  def remove_non_existent_fields
    unless options[:gentle]
      existing_column_names.reject do |existing_column_name|
        find_ideal_column existing_column_name
      end.each do |existing_column_name|
        if dry_run
          log_dry "remove column #{model.table_name}.#{existing_column_name}"
        else
          connection.remove_column model.table_name, existing_column_name
        end
      end
    end
  end

  def add_new_fields
    ideal_columns.reject do |ideal_column|
      find_existing_column ideal_column.name
    end.each do |ideal_column|
      if dry_run
        log_dry "add column #{model.table_name}.#{ideal_column.name} #{ideal_column.type} #{ideal_column.options.inspect}"
      else
        connection.add_column model.table_name, ideal_column.name, ideal_column.type, ideal_column.options
      end
    end
  end

  def change_fields_types
    existing_columns_hash.reject do |existing_column_name, existing_column|
      existing_column_name.to_s == model.primary_key.to_s
    end.each do |existing_column_name, existing_column|
      next unless (ideal_column = find_ideal_column(existing_column_name))

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
        if dry_run
          log_dry "change column #{model.table_name}.#{existing_column_name} #{ideal_column.type} #{option_changes.inspect}"
        else
          connection.change_column model.table_name, existing_column_name, ideal_column.type, option_changes
        end
      end
    end
  end

  def remove_non_existent_indexes
    unless options[:gentle]
      existing_index_names.reject do |existing_index_name|
        find_ideal_index existing_index_name
      end.each do |existing_index_name|
        if dry_run
          log_dry "remove index #{model.table_name} #{existing_index_name}"
        else
          connection.remove_index model.table_name, :name => existing_index_name
        end
      end
    end
  end

  def add_new_indexes
    ideal_indexes.reject do |ideal_index|
      find_existing_index ideal_index.name
    end.each do |ideal_index|
      if dry_run
        log_dry "add index #{model.table_name}.#{ideal_index.column_name} #{ideal_index.options.inspect}"
      else
        connection.add_index model.table_name, ideal_index.column_name, ideal_index.options
      end
    end
  end

end
