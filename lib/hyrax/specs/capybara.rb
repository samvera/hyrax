# without lines 1-12, screenshots and html captured from failing specs are blank
# source: https://github.com/mattheworiordan/capybara-screenshot/issues/225
require "action_dispatch/system_testing/test_helpers/setup_and_teardown"
::ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown.module_eval do
  def before_setup
    super
  end

  def after_teardown
    super
  end
end

require 'capybara/rspec'
require 'capybara/rails'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'
require 'webdrivers' unless ENV['IN_DOCKER'].present? || ENV['HUB_URL'].present?

Capybara.default_driver = :rack_test # This is a faster driver
Capybara.javascript_driver = :selenium_chrome_headless # This is slower
Capybara.default_max_wait_time = ENV.fetch('CAPYBARA_WAIT_TIME', 10) # We may have a slow application, let's give it some time.

Capybara::Screenshot.autosave_on_failure = false
Capybara::Screenshot.prune_strategy = { keep: 10 }

# Save CircleCI artifacts

def save_timestamped_page_and_screenshot(page, meta)
  filename = File.basename(meta[:file_path])
  line_number = meta[:line_number]

  time_now = Time.zone.now
  timestamp = "#{time_now.strftime('%Y-%m-%d-%H-%M-%S.')}#{'%03d' % (time_now.usec / 1000).to_i}"

  artifact_dir = ENV['CI'] ? "/tmp/test-results" : Rails.root.join('tmp', 'capybara')

  screenshot_name = "screenshot-#{filename}-#{line_number}-#{timestamp}.png"
  screenshot_path = "#{artifact_dir}/#{screenshot_name}"
  page.save_screenshot(screenshot_path)

  page_name = "html-#{filename}-#{line_number}-#{timestamp}.html"
  page_path = "#{artifact_dir}/#{page_name}"
  page.save_page(page_path)

  puts "\n  Screenshot: #{screenshot_path}"
  puts "  HTML: #{page_path}"
end

RSpec.configure do |config|
  config.after(:each, :js) do |example|
    save_timestamped_page_and_screenshot(Capybara.page, example.metadata) if example.exception
  end
end
