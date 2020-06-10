# frozen_string_literal: true
require 'rake'

# Run the jasmine tests by running the jasmine:ci rake command and parses the output for failures.
# The spec will fail if any jasmine tests fails.
RSpec.describe "Jasmine" do
  it "expects all jasmine tests to pass" do
    load_rake_environment ["#{jasmine_path}/lib/jasmine/tasks/jasmine.rake"]
    # @rake.options.trace = true
    jasmine_out = run_task 'jasmine:ci'
    if jasmine_out.include? "0 failures"
      js_specs_count = Dir['spec/javascripts/**/*_spec.{js,coffee,js.coffee}'].count
      puts "#{jasmine_out.match(/\n(.+) specs/)[1]} jasmine specs run (in #{js_specs_count} jasmine test files)"
    else
      puts "\n\n************************  Jasmine Output *************"
      puts jasmine_out
      puts "************************  Jasmine Output *************\n\n"
    end
    expect(jasmine_out).to include "0 failures"
    expect(jasmine_out).not_to include "\n0 specs"
  end
end

def jasmine_path
  Gem.loaded_specs['jasmine'].full_gem_path
end
