# -*- encoding : utf-8 -*-
require 'rails/generators'

class Sufia::Upgrade600Generator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator for upgrading sufia to 6.0 makes the following changes to your application:
 1. runs the model upgrade
       """

  def migrations
    generate "sufia:models:upgrade600"
  end
end
