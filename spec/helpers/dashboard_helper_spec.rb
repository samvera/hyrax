require 'spec_helper'

describe DashboardHelper, type: :helper do
  describe "#render_recent_activity" do
    context "when there is no activity" do
      it "returns a messages stating the user has no recent activity" do
        assign(:activity, [])
        expect(helper.render_recent_activity).to include("no recent activity")
      end
    end
  end

  describe "#render_recent_notifications" do
    context "when there are no notifications" do
      it "returns a messages stating the user has no recent notifications" do
        assign(:notifications, [])
        expect(helper.render_recent_notifications).to include("no notifications")
      end
    end
  end

  describe "#on_the_dashboard?" do
    it "returns false for controllers that aren't a part of the dashboard" do
      allow(helper).to receive(:params).and_return(controller: "foo")
      expect(helper).to_not be_on_the_dashboard
    end

    it "returns true for controllers that are part of the dashboard" do
      allow(helper).to receive(:params).and_return(controller: "my/works")
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return(controller: "my/collections")
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return(controller: "my/highlights")
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return(controller: "my/shares")
      expect(helper).to be_on_the_dashboard
    end
  end

  describe "#on_my_works" do
    it "returns false when the controller isn't my works" do
      allow(helper).to receive(:params).and_return(controller: "my/collections")
      expect(helper).to_not be_on_my_works
    end
    it "returns true when the controller is my works" do
      allow(helper).to receive(:params).and_return(controller: "my/works")
      expect(helper).to be_on_my_works
    end
  end

  describe "#number_of_works" do
    let(:conn) { ActiveFedora::SolrService.instance.conn }
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }
    before do
      create_models("GenericWork", user1, user2)
    end

    it "finds 3 works" do
      expect(helper.number_of_works(user1)).to eq(3)
    end
  end

  describe "#number_of_files" do
    let(:conn) { ActiveFedora::SolrService.instance.conn }
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }
    before do
      create_models("FileSet", user1, user2)
    end

    it "finds only 3 files" do
      expect(helper.number_of_files(user1)).to eq(3)
    end
  end

  describe "#number_of_collections" do
    let(:conn) { ActiveFedora::SolrService.instance.conn }
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }
    before do
      create_models("Collection", user1, user2)
    end

    it "finds only 3 files" do
      expect(helper.number_of_collections(user1)).to eq(3)
    end
  end

  def create_models(model, user1, user2)
    # deposited by the first user
    3.times do |t|
      conn.add id: "199#{t}", Solrizer.solr_name('depositor', :stored_searchable) => user1.user_key, "has_model_ssim" => [model],
               Solrizer.solr_name('depositor', :symbol) => user1.user_key
    end

    # deposited by the second user, but editable by the first
    conn.add id: "1994", Solrizer.solr_name('depositor', :stored_searchable) => user2.user_key, "has_model_ssim" => [model],
             Solrizer.solr_name('depositor', :symbol) => user2.user_key, "edit_access_person_ssim" => user1.user_key
    conn.commit
  end
end
