require "bundler/gem_tasks"
require "rake"
require "rake/testtask"

Rake::TestTask.new(:test) do |test|
  test.libs << 'spec'
  test.test_files = Dir['spec/**/*_spec.rb']
  test.verbose = true
end

task :test_each_db_adapter do
  %w{ mysql sqlite3 postgresql }.each do |db_adapter|
    puts
    puts "#{'*'*10} Running #{db_adapter} tests"
    puts
    puts `bundle exec rake test DB_ADAPTER=#{db_adapter} TEST=spec/#{db_adapter}_spec.rb`
  end
end

task :default => :test_each_db_adapter
task :spec => :test_each_db_adapter
