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

    it 'finds 3 works' do
      expect(helper.number_of_works(user1)).to eq(3)
    end
  end

  describe "#link_to_works" do
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }

    before do
      create_models("GenericWork", user1, user2)
    end

    context 'when valkyrie is not used' do
      it "generates a link to the user's works" do
        expect(Hyrax.config).to receive(:use_valkyrie?).and_return(false)
        expect(helper.link_to_works(user1)).to include 'generic_type_sim%5D%5B%5D=Work'
      end
    end

    context 'when valkyrie is used' do
      it "generates a link to the user's works" do
        expect(Hyrax.config).to receive(:use_valkyrie?).and_return(true)
        expect(helper.link_to_works(user1)).to include 'generic_type_si%5D%5B%5D=Work'
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
    generic_types_mapping = {
      'GenericWork' => 'Work',
      'Collection' => 'Collection',
      'FileSet' => 'FileSet'
    }

    # deposited by the first user
    3.times do |t|
      solr_service.add({ id: "199#{t}", "depositor_tesim" => user1.user_key, "has_model_ssim" => [model],
                         "depositor_ssim" => user1.user_key, "generic_type_si" => generic_types_mapping[model] })
    end

    # deposited by the second user, but editable by the first
    solr_service.add({ id: "1994", "depositor_tesim" => user2.user_key, "has_model_ssim" => [model],
                       "depositor_ssim" => user2.user_key, "generic_type_si" => generic_types_mapping[model],
                       "edit_access_person_ssim" => user1.user_key })
    solr_service.commit
  end
end
