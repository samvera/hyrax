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

Capybara.save_path = ENV['CI'] ? "/tmp/test-results" : Rails.root.join('tmp', 'capybara')

options = Selenium::WebDriver::Chrome::Options.new.tap do |opts|
  opts.add_argument("--headless=new") if ENV["CHROME_HEADLESS_MODE"]
  # opts.add_argument("--no-sandbox")
  # opts.add_argument("--disable-dev-shm-usage")
  opts.add_argument("--disable-gpu") if Gem.win_platform?
  opts.add_argument("--window-size=1440,1440")
  # opts.add_argument("--enable-features=NetworkService,NetworkServiceInProcess")
  # opts.add_argument("--disable-features=VizDisplayCompositor")
end

Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
  driver = Capybara::Selenium::Driver.new(app,
                                      browser: :remote,
                                      capabilities: options,
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

# ip = IPSocket.getaddress(Socket.gethostname)
ip = `hostname -s`.strip
Capybara.app_host = "http://#{ip}:#{Capybara.server_port}"

Capybara.default_driver = :rack_test # This is a faster driver
Capybara.javascript_driver = :selenium_chrome_headless_sandboxless # This is slower
Capybara.disable_animation = true
Capybara.default_max_wait_time = ENV.fetch('CAPYBARA_WAIT_TIME', 10) # We may have a slow application, let's give it some time.

Capybara::Screenshot.register_driver(:selenium_chrome_headless_sandboxless) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.autosave_on_failure = true
Capybara::Screenshot.prune_strategy = :keep_last_run

# Save CircleCI artifacts

def save_timestamped_page_and_screenshot(page, meta)
  filename = File.basename(meta[:file_path])
  line_number = meta[:line_number]

  time_now = Time.zone.now
  timestamp = "#{time_now.strftime('%Y-%m-%d-%H-%M-%S.')}#{'%03d' % (time_now.usec / 1000).to_i}"

  artifact_dir = Capybara.save_path

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
    # Quitting forces the browser session to be reinitialized during the next :js spec.
    # This is slower but more resilient to timeouts (in theory).
    Capybara.page.driver.quit
  end
end
