require 'thread'

module ActiveRecordInlineSchema::ActiveRecordClassMethods
  MUTEX = ::Mutex.new

  def inline_schema_config
    if superclass != ::ActiveRecord::Base
      return base_class.inline_schema_config
    end
    @inline_schema_config || MUTEX.synchronize do
      @inline_schema_config ||= ::ActiveRecordInlineSchema::Config.new self
    end
  end

  def col(column_name, options = {})
    inline_schema_config.add_ideal_column column_name, options
  end

  # this is not a typo - specify column name, not index name
  def add_index(column_name, options = {})
    inline_schema_config.add_ideal_index column_name, options
  end

  def auto_upgrade!(create_table_options = nil)
    inline_schema_config.apply create_table_options
  end
end
