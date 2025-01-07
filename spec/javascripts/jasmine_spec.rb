# frozen_string_literal: true
require 'English'

# Run the jasmine tests by running the karma javascript test framework
# The spec will fail if any jasmine tests fails.
RSpec.describe "Jasmine" do
  before do
    `cd $RAILS_ROOT && bundle exec rake assets:precompile` if ENV['RAILS_ROOT']
  end

  it "expects all jasmine tests to pass" do
    # Ensure capybara is not using the remote browser
    Capybara.using_driver(Capybara.javascript_driver) { Capybara.current_session.quit }

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
