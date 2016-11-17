require 'rspec/matchers'

if defined?($SHOW_MATCHERS)
  module RSpec::Shim
    def define(matcher_name, *args, &block)
      $SHOW_MATCHERS[matcher_name] = caller.first.split(':')[0..1]
      super
    end

    def matcher(matcher_name, *args, &block)
      $SHOW_MATCHERS[matcher_name] = caller.first.split(':')[0..1]
      super
    end
  end

  RSpec::Matchers.extend(RSpec::Shim)
end

require 'rspec/matchers/dsl'
require 'rspec-html-matchers'
require 'rspec-rails'
require 'rspec/rails'
require 'rspec/rails/matchers'

Dir[File.expand_path('../matchers/**/*.rb', __FILE__)].each { |f| require f }
