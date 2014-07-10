require "bundler/gem_tasks"
require "rspec/core"
require "rspec/core/rake_task"

Rake::Task["spec"].clear
RSpec::Core::RakeTask.new(:spec) do |t|
  t.fail_on_error = false
  t.rspec_opts = %w[-f JUnit -o results.xml]
end

desc "Run RSpec with code coverage"
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task["spec"].execute
end
task :default => :spec
