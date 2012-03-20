require 'test_helper'
require 'rails/performance_test_help'

class AuthoritiesControllerTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  self.profile_options = {:formats => [:call_tree]}
  def test_authorities_query
    get '/authorities/generic_files/subject'
  end
end
