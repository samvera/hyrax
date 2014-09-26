require 'spec_helper'

describe User do

  describe "user_key" do
    let(:user) { User.new.tap {|u| u.email = "foo@example.com"} }
    before do
      allow(user).to receive(:username).and_return('foo')
    end

    it "should return email" do
      expect(user.user_key).to eq 'foo@example.com'
    end

    it "should return username" do
      allow(Devise).to receive(:authentication_keys).and_return([:username])
      expect(user.user_key).to eq 'foo'
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
