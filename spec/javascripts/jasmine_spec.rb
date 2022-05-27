# frozen_string_literal: true
require 'English'
require 'rake'

# Run the jasmine tests by running the karma javascript test framework
# The spec will fail if any jasmine tests fails.
RSpec.describe "Jasmine" do
  before do
    Rails.application.load_tasks
    Rake::Task["assets:clobber"].invoke
    Rake::Task["assets:precompile"].invoke
  end

  it "expects all jasmine tests to pass" do
    jasmine_out = `node_modules/karma/bin/karma start`

    if $CHILD_STATUS.exitstatus == 0
      puts "\nJasmine: #{jasmine_out.strip.lines.last}\n"
    else
      puts "\n\n************* Jasmine Output *************"
      puts jasmine_out
      puts "************* Jasmine Output *************\n\n"
    end

    expect($CHILD_STATUS.exitstatus).to eq 0
    expect(jasmine_out).not_to include "\nTOTAL: 0 SUCCESS"
  end
end
