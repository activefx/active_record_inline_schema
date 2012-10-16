require 'rubygems'
require 'bundler/setup'

if ::Bundler.definition.specs['debugger'].first
  require 'debugger'
elsif ::Bundler.definition.specs['ruby-debug'].first
  require 'ruby-debug'
end

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'

require 'active_record_inline_schema'

# require 'logger'
# ActiveRecord::Base.logger = Logger.new($stderr)
# ActiveRecord::Base.logger.level = Logger::DEBUG

module SpecHelper
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def db_columns
      connection.columns(table_name).map(&:name).sort
    end

    def db_indexes
      connection.indexes(table_name).map(&:name).sort
    end

    def schema_columns
      inline_schema_config.ideal_columns.map { |c| c.name.to_s }.sort
    end

    def schema_indexes
      inline_schema_config.ideal_indexes.map { |c| c.name.to_s }.sort
    end

    def safe_reset_column_information
      if connection.respond_to?(:schema_cache)
        connection.schema_cache.clear!
      end
      reset_column_information
    end
  end
end

require File.expand_path('../models.rb', __FILE__)
