require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

desc "Run RuboCop style and lint checks"
Rubocop::RakeTask.new(:rubocop)

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--color --format documentation"
end

task :test => [:rubocop, :spec]
task :default => :test
