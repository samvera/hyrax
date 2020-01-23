require 'spec_helper'
require 'spicy_wings'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'spicy_wings', 'support', 'matchers', '**', '*.rb'))].each { |f| require f }
