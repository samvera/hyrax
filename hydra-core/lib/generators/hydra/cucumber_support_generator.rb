# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'

module Hydra
class CucumberSupportGenerator < Rails::Generators::Base

  source_root File.expand_path('../../../../test_support/features', __FILE__)

  argument :features_dir, :type => :string , :default => "features"

  desc """
  This Generator copies Hydra's cucumber step definitions and paths into your application's features directory.
  We have plans to provide the step definitions directly through the hydra-head gem without requiring this step of copying the files.
  In the meantime, you need to copy the files in order to use them.

  Defaults to assuming that your cucumber features live in a directory called \"features\".  To pass in an alternative path to your features directory,

  rails generate hydra:cucumber_support test_support/features

  """

  def copy_cucumber_support
    directory("step_definitions", "#{features_dir}/step_definitions")
    copy_file("support/paths.rb", "#{features_dir}/support/paths.rb")
  end

end
end