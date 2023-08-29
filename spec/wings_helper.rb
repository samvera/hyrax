# frozen_string_literal: true
require 'spec_helper'
unless Hyrax.config.disable_wings
  require 'wings'

  Dir[File.expand_path(File.join(File.dirname(__FILE__), 'wings', 'support', 'matchers', '**', '*.rb'))].each { |f| require f }
end
