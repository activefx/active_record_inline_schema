class ActiveRecordInlineSchema::Config::Column
  DEFAULT_TYPE = :string

  attr_reader :parent
  attr_reader :name
  attr_reader :type
  attr_reader :options

  def initialize(parent, name, options)
    @parent = parent
    @name = name.to_s
    options = options.symbolize_keys
    if options.slice(:precision, :scale).keys.length == 1
      raise ::ArgumentError, %{[active_record_inline_schema] :precision and :scale must always be specified together}
    end
    @type = options.fetch(:type, DEFAULT_TYPE).to_sym
    @options = options.except :type, :name
  end

  def inject(table_definition)
    if type != :primary_key and table_definition.respond_to?(type)
      table_definition.send type, name, options
    else
      table_definition.column name, type, options
    end
  end

  def eql?(other)
    other.is_a?(self.class) and parent == other.parent and name == other.name and options == other.options
  end

  def hash
    [parent, name, options].hash
  end
end
