RSpec.describe Hyrax::DashboardHelperBehavior, type: :helper do
  describe "#on_the_dashboard?" do
    it "returns false for controllers that aren't a part of the dashboard" do
      allow(helper).to receive(:params).and_return(controller: "foo")
      expect(helper).not_to be_on_the_dashboard
    end

    it "returns true for controllers that are part of the dashboard" do
      allow(helper).to receive(:params).and_return(controller: "hyrax/my/works")
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return(controller: "hyrax/my/collections")
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return(controller: "hyrax/my/highlights")
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return(controller: "hyrax/my/shares")
      expect(helper).to be_on_the_dashboard
    end
  end

  describe "#on_my_works" do
    it "returns false when the controller isn't my works" do
      allow(helper).to receive(:params).and_return(controller: "hyrax/my/collections")
      expect(helper).not_to be_on_my_works
    end
    it "returns true when the controller is my works" do
      allow(helper).to receive(:params).and_return(controller: "hyrax/my/works")
      expect(helper).to be_on_my_works
    end
  end

  describe "#number_of_works" do
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }

    before do
      create_models(:work, user1, user2)
    end

    it "finds 3 works" do
      expect(helper.number_of_works(user1)).to eq(1)
    end
  end

  describe "#number_of_files" do
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }

    before do
      create_models(:file_set, user1, user2)
    end

    it "finds only 3 files" do
      expect(helper.number_of_files(user1)).to eq(1)
    end
  end

  describe "#number_of_collections" do
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }

    before do
      create_models(:collection, user1, user2)
    end

    it "finds only 3 files" do
      expect(helper.number_of_collections(user1)).to eq(1)
    end
  end

  def create_models(model, user1, user2)
    # deposited by the first user
    create_for_repository(model, user: user1)

    # deposited by the second user, but editable by the first
    create_for_repository(model, user: user2, edit_users: [user1.user_key])
  end
end
