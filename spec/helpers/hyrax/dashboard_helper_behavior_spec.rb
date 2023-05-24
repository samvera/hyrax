# frozen_string_literal: true
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

  describe "#number_of_works" do
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }

    before do
      create_models("GenericWork", user1, user2)
    end

    it "finds 2 works" do
      expect(helper.number_of_works(user1)).to eq(2)
    end

    context "with an over-riddent :where clause" do
      it "finds 3 works when passed an empty where" do
        expect(helper.number_of_works(user1, where: {})).to eq(3)
      end

      it "limits to those matching the where clause" do
        expect(helper.number_of_works(user1, where: { "generic_type_sim" => "Big Work" })).to eq(1)
      end
    end
  end

  describe "#number_of_files" do
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
    solr_service = Hyrax::SolrService

    # deposited by the first user
    2.times do |t|
      solr_service.add({ id: "199#{t}", "depositor_tesim" => user1.user_key, "has_model_ssim" => [model],
                         "depositor_ssim" => user1.user_key, "generic_type_sim" => "Work" })
    end

    solr_service.add({ id: "1993", "depositor_tesim" => user1.user_key, "generic_type_sim" => "Big Work", "has_model_ssim" => [model], "depositor_ssim" => user1.user_key })

    # deposited by the second user, but editable by the first
    solr_service.add({ id: "1994", "depositor_tesim" => user2.user_key, "has_model_ssim" => [model],
                       "depositor_ssim" => user2.user_key, "edit_access_person_ssim" => user1.user_key })
    solr_service.commit
  end
end
