require 'rails/generators'

class Hyrax::ChartkickGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc '
This generator makes the following changes to your application:
 1. Adds chartkick dependency to application Gemfile
       '

  def banner
    say_status('info', 'Generating Chartkick charting library', :blue)
  end

  def add_to_gemfile
    gem 'chartkick', '~> 2.3'

    Bundler.with_clean_env do
      run "bundle install"
    end
  end
end
