require 'test_helper'
require 'rails/performance_test_help'

class GenericFileModelTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  self.profile_options = {:formats => [:call_tree]}
  def test_creation
    GenericFile.create
  end
  def test_new_then_save
    gf = GenericFile.new
    gf.save
  end
  def test_to_solr
    gf = GenericFile.create
    gf.to_solr
  end
end
