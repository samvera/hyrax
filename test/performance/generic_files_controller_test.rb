require 'test_helper'
require 'rails/performance_test_help'
require 'capybara/rails'

class GenericFilesControllerTest < ActionDispatch::PerformanceTest
  include Capybara::DSL
  # Refer to the documentation for all available options
  self.profile_options = {:formats => [:call_tree]}
  def setup
    sign_in FactoryGirl.create(:user)
    @user = User.create(:email => "testuser@example.com", 
                        :password => "password", 
                        :password_confirmation => "password")
    user.confirmed_at Time.now
    @user.save
    visit '/users/sign_in'
    fill_in 'Email', :with => @user.email
    fill_in 'Password', :with => "password"
    click_link_or_button('Sign in')
    @user
  end
  def test_upload_page
    get new_generic_file_path
    upload_file
    #@user.delete
  end
  def upload_file
  
      file = fixture_file_upload('spec/fixtures/world.png','image/png')
      #xhr :post, :generic_file, :Filedata=>[file], :Filename=>"The world", :permission=>{"group"=>{"public"=>"discover"}}
     post generic_files_path, :post => {:pid => 'test:789', :Filedata=>[file], :Filename=>"The world", :permission=>{"group"=>{"public"=>"discover"}}}
     #      saved_file = GenericFile.find('test:123')
     
  end
end
