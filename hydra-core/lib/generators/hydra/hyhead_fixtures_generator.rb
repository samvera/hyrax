# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'

module Hydra
class HyheadFixturesGenerator < Rails::Generators::Base

  source_root File.expand_path('../../../../', __FILE__)

  desc """
  This Generator copies the hydra-head sample/test objects into your application's test_support/fixtures directory
  These objects are useful for getting a sense of how hydra works, but you will want to delete them and create your own
  fixtures to run your application's tests against.

  After running this generator, you can import your fixtures into fedora & solr by running

  rake hydra:fixtures:refresh
  rake hydra:fixtures:refresh RAILS_ENV=test

  """

  def copy_hyhead_fixtures
    directory("test_support/fixtures", "spec/fixtures")
  end

end
end