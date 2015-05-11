# -*- encoding : utf-8 -*-
require 'rails/generators'

class Sufia::Upgrade700Generator < Rails::Generators::Base

  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator for upgrading sufia to 7.0 makes the following changes to your application:
       """

  def migrations
    generate "sufia:models:upgrade700"
  end

end
