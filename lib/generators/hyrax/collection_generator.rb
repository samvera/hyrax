# frozen_string_literal: true
require 'rails/generators'

module Hyrax
  class CollectionGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    desc 'This generator makes the following changes to your application:
   1. Creates a collection model.
'

    def create_collection
      copy_file 'app/models/collection.rb', 'app/models/collection.rb'
    end
  end
end
