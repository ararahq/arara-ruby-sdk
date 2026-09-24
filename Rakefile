require "rake/testtask"

Rake::TestTask.new(:test) do |task|
  task.libs << "test" << "lib"
  task.test_files = FileList["test/**/*_test.rb"]
  task.warning = true
end

task default: :test
