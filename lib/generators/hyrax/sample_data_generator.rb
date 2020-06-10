# frozen_string_literal: true
require 'rails/generators'

module Hyrax
  class SampleDataGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    desc 'This generator copies over a file that creates sample data via `rake db:seed`'
    def copy_sample_data
      copy_file 'db/seeds.rb', 'db/seeds.rb'
    end
  end
end
