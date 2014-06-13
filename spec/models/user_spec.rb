require 'spec_helper'

describe User do
  before(:all) do
    @user = FactoryGirl.find_or_create(:jill)
    @another_user = FactoryGirl.find_or_create(:archivist)
  end
  after(:all) do
    @user.delete
    @another_user.delete
  end
  it "should have an email" do
    @user.user_key.should == "jilluser@example.com"
  end
  it "should have activity stream-related methods defined" do
    @user.should respond_to(:stream)
    @user.should respond_to(:events)
    @user.should respond_to(:profile_events)
    @user.should respond_to(:create_event)
    @user.should respond_to(:log_event)
    @user.should respond_to(:log_profile_event)
  end
  it "should have social attributes" do
    @user.should respond_to(:twitter_handle)
    @user.should respond_to(:facebook_handle)
    @user.should respond_to(:googleplus_handle)
    @user.should respond_to(:linkedin_handle)
  end
  it "should redefine to_param to make redis keys more recognizable (and useable within Rails URLs)" do
    @user.to_param.should == "jilluser@example-dot-com"
  end
  it "should have a cancan ability defined" do
    @user.should respond_to(:can?)
  end
  it "should not have any followers" do
    @user.followers_count.should == 0
    @another_user.follow_count.should == 0
  end
  describe "follow/unfollow" do
    before(:all) do
      @user = FactoryGirl.find_or_create(:jill)
      @another_user = FactoryGirl.find_or_create(:archivist)
      @user.follow(@another_user)
    end
    after do
      @user.delete
      @another_user.delete
    end
    it "should be able to follow another user" do
      expect(@user).to be_following(@another_user)
      expect(@another_user).to_not be_following(@user)
      expect(@another_user).to be_followed_by(@user)
      expect(@user).to_not be_followed_by(@another_user)
    end
    it "should be able to unfollow another user" do
      @user.stop_following(@another_user)
      expect(@user).to_not be_following(@another_user)
      expect(@another_user).to_not be_followed_by(@user)
    end
  end

  describe "trophy_files" do
    let(:user) { @user } 
    let(:file1) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } } 
    let(:file2) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } } 
    let(:file3) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } } 
    let!(:trophy1) { user.trophies.create!(generic_file_id: file1.noid) }
    let!(:trophy2) { user.trophies.create!(generic_file_id: file2.noid) }
    let!(:trophy3) { user.trophies.create!(generic_file_id: file3.noid) }

    it "should return a list of generic files" do
      expect(user.trophy_files).to eq [file1, file2, file3]
    end

  end
end
