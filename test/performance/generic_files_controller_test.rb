Brequire 'test_helper'
require 'rails/performance_test_help'
require 'capybara/rails'

class GenericFilesControllerTest < ActionDispatch::PerformanceTest
  include Capybara::DSL
  # Refer to the documentation for all available options
  self.profile_options = {:formats => [:call_tree]}
  def setup
    user = User.create(:password => "foobardefault",
                       :password_confirmation => "foobardefault",
                       :email => "adminuser")
    #user.confirmed_at Time.now
    #user.save!
    visit '/users/sign_in'
    fill_in 'Email', :with => user.email
    fill_in 'Password', :with => "foobardefault"
    click_link_or_button('Sign in')
    user
  end
  def test_upload_page
    get new_generic_file_path
  end
  def upload_file
    file = fixture_file_upload('/world.png','image/png')
    post generic_file_path, :post => {:Filedata=>[file], :Filename=>"The world"}
  end
end
