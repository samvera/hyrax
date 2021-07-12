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

if ENV['IN_DOCKER'].present? || ENV['HUB_URL'].present?
  args = %w[disable-gpu no-sandbox whitelisted-ips window-size=1400,1400]
  args.push('headless') if ActiveModel::Type::Boolean.new.cast(ENV['CHROME_HEADLESS_MODE'])

  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(chromeOptions: { args: args })

  Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
    driver = Capybara::Selenium::Driver.new(app,
                                       browser: :remote,
                                       desired_capabilities: capabilities,
                                       url: ENV['HUB_URL'])

    # Fix for capybara vs remote files. Selenium handles this for us
    driver.browser.file_detector = lambda do |args|
      str = args.first.to_s
      str if File.exist?(str)
    end

    driver
  end

  Capybara.server_host = '0.0.0.0'
  Capybara.server_port = 3010

  ip = IPSocket.getaddress(Socket.gethostname)
  Capybara.app_host = "http://#{ip}:#{Capybara.server_port}"
else
  TEST_HOST = 'localhost:3000'.freeze
  # @note In January 2018, TravisCI disabled Chrome sandboxing in its Linux
  #       container build environments to mitigate Meltdown/Spectre
  #       vulnerabilities, at which point Hyrax could no longer use the
  #       Capybara-provided :selenium_chrome_headless driver (which does not
  #       include the `--no-sandbox` argument).
  Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
    browser_options = ::Selenium::WebDriver::Chrome::Options.new
    browser_options.args << '--headless'
    browser_options.args << '--disable-gpu'
    browser_options.args << '--no-sandbox'
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
  end
end

Capybara.default_driver = :rack_test # This is a faster driver
Capybara.javascript_driver = :selenium_chrome_headless_sandboxless # This is slower
Capybara.default_max_wait_time = ENV.fetch('CAPYBARA_WAIT_TIME', 10) # We may have a slow application, let's give it some time.

Capybara::Screenshot.register_driver(:selenium_chrome_headless_sandboxless) do |driver, path|
  driver.browser.save_screenshot(path)
end

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
