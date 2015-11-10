require 'spec_helper'
require 'rake'

# Run the jasmine tests by running the jasmine:ci rake command and parses the output for failures.
# The spec will fail if any jasmine tests fails.
describe "Jasmine" do
  it "expects all jasmine tests to pass" do
    load_rake_environment ["#{jasmine_path}/lib/jasmine/tasks/jasmine.rake"]
    jasmine_out = run_task 'jasmine:ci'
    unless jasmine_out.include? "0 failures"
      puts "\n\n************************  Jasmine Output *************"
      puts jasmine_out
      puts "************************  Jasmine Output *************\n\n"
    end
    expect(jasmine_out).to include "\n0 failures"
    expect(jasmine_out).to_not include "\n0 specs"
  end
end

def jasmine_path
  Gem.loaded_specs['jasmine'].full_gem_path
end
