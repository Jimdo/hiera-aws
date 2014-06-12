require "bundler/gem_tasks"
require "rspec/core/rake_task"

# RuboCop only works with newer Ruby versions
if RUBY_VERSION >= "1.9.2"
  require "rubocop/rake_task"

  desc "Run RuboCop style and lint checks"
  RuboCop::RakeTask.new(:rubocop) do |t|
    t.options = ["-D"]
  end

  task :test => :rubocop
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--color --format documentation"
end

task :test => :spec
task :default => :test
