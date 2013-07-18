require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SufiaHelper do
  describe "link_to_profile" do
    it "should use User#to_params" do
      u = User.new
      u.stub(:user_key).and_return('justin@example.com')
      User.should_receive(:find_by_user_key).with('justin@example.com').and_return(u)
      helper.link_to_profile('justin@example.com').should == "<a href=\"/users/justin@example-dot-com\">justin@example.com</a>"
    end
  end
end
