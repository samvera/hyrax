# frozen_string_literal: true
require 'rails/generators'

class Hyrax::ListenersGenerator < Rails::Generators::Base
  desc """
    This generator adds templates for Hyrax::Publisher listeners to your application
       """

  source_root File.expand_path('../templates', __FILE__)

  def inject_listener
    copy_file 'app/listeners/hyrax_listener.rb', 'app/listeners/hyrax_listener.rb'
  end

  def inject_listener_initialier
    copy_file 'config/initializers/publisher.rb', 'config/initializers/publisher.rb'
  end
end
