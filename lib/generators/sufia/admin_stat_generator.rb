# -*- encoding : utf-8 -*-
require 'rails/generators'

class Sufia::AdminStatGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc """
This is a generator for adding Admin Stats into sufia
       """

  def insert_stats_admin
    copy_file 'sufia/stats_admin.rb', 'config/initializers/stats_admin.rb'
  end
end
