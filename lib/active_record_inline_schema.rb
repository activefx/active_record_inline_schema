require 'active_support/core_ext'
require 'active_record'

module ActiveRecordInlineSchema
end

require 'active_record_inline_schema/config'
require 'active_record_inline_schema/config/column'
require 'active_record_inline_schema/config/index'
require 'active_record_inline_schema/active_record_class_methods'

ActiveRecord::Base.extend ActiveRecordInlineSchema::ActiveRecordClassMethods
