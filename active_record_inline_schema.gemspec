# -*- encoding: utf-8 -*-
require File.expand_path("../lib/active_record_inline_schema/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "active_record_inline_schema"
  s.version     = ActiveRecordInlineSchema::VERSION
  s.authors     = ["Seamus Abshere", "Davide D'Agostino"]
  s.email       = ["seamus@abshere.net", "d.dagostino@lipsiasoft.com"]
  s.homepage    = "https://github.com/seamusabshere/active_record_inline_schema"
  s.summary     = %q{Define table structure (columns and indexes) inside your ActiveRecord models like you can do in migrations. Also similar to DataMapper inline schema syntax.}
  s.description = %q{Specify columns like you would with ActiveRecord migrations and then run .auto_upgrade! Based on the mini_record gem from Davide D'Agostino, it adds fewer aliases, doesn't create timestamps and relationship columns automatically.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency "activerecord", ">=3"
  s.add_runtime_dependency 'lock_method'
  s.add_runtime_dependency 'cache_method'
  # s.add_runtime_dependency "activerecord", "~>3.0" # must use mysql2 ~>0.2 to test
  # s.add_runtime_dependency "activerecord", "~>3.1"
  # s.add_runtime_dependency "activerecord", "~>3.2"

  # dev dependencies appear to be in the Gemfile
end
