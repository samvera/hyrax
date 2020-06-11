# frozen_string_literal: true
require 'spec_helper'
require 'wings'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'wings', 'support', 'matchers', '**', '*.rb'))].each { |f| require f }
