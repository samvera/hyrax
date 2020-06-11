# frozen_string_literal: true
require 'power_converter'

pattern = File.expand_path('../power_converters/**/*.rb', __FILE__)
Dir.glob(pattern).each do |filename|
  require filename
end
