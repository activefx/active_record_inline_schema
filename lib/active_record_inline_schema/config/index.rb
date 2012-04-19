require 'zlib'
require 'thread'

class ActiveRecordInlineSchema::Config::Index
  attr_reader :parent
  attr_reader :column_name
  attr_reader :initial_options

  delegate :connection, :to => :parent
  delegate :model, :to => :parent

  def initialize(parent, column_name, options)
    @parent = parent
    @column_name = column_name.to_s
    @initial_options = options.symbolize_keys
    @name_mutex = ::Mutex.new
  end

  def name
    @name || @name_mutex.synchronize do
      @name ||= begin
        max_name_length = connection.index_name_length
        prototype = connection.index_name model.table_name, :column => column_name
        if prototype.length < max_name_length
          prototype
        else
          prototype[0..(max_name_length-11)] + ::Zlib.crc32(prototype).to_s
        end
      end
    end
  end

  def options
    @initial_options.merge(:column_name => column_name, :name => name)
  end

  def eql?(other)
    other.is_a?(self.class) and parent == other.parent and column_name == other.column_name and initial_options == other.initial_options
  end

  def hash
    [parent, column_name, initial_options].hash
  end
end
