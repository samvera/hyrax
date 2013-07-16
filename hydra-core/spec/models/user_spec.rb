require 'spec_helper'

describe User do

  describe "user_key" do
    before do
      @user = User.new.tap {|u| u.email = "foo@example.com"}
      @user.stub(:username =>'foo')
    end

    it "should return email" do
      @user.user_key.should == 'foo@example.com'
    end

    it "should return username" do
      Devise.stub(:authentication_keys =>[:username])
      @user.user_key.should == 'foo'
    end

  end

end

module UserTestAttributes
  ['first_name','last_name','full_name','affiliation','photo'].each do |attr|
    class_eval <<-EOM
      def #{attr}
        "test_#{attr}"
      end
    EOM
  end
end
