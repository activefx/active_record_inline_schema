require 'rubygems' unless defined?(Gem)
require 'active_record'
require 'active_record_inline_schema/auto_schema'

ActiveRecord::Base.send(:include, ActiveRecordInlineSchema::AutoSchema)
