# Headless for Jenkins CI builds
Before("@javascript") do
  if ENV['HEADLESS'] == 'true'
    Capybara.current_driver = :selenium
    require 'headless'
    headless = Headless.new
    headless.start
    at_exit do
      headless.destroy
    end
  end
end
