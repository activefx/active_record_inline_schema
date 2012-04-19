source :rubygems

gemspec

gem 'rake'
gem 'minitest'
gem 'minitest-reporters'

platforms :ruby do
  # if RUBY_VERSION >= '1.9'
  #   gem 'debugger'
  # else
  #   gem 'ruby-debug19'
  # end
  # gem 'mysql2', '~>0.2'
  gem 'mysql2', '>=0.3'
  gem 'sqlite3'
  gem 'pg'
end

platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'activerecord-jdbcmysql-adapter'
  gem 'activerecord-jdbcpostgresql-adapter'
end
