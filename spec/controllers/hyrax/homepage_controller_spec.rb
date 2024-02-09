# frozen_string_literal: true
RSpec.describe Hyrax::HomepageController, type: :controller do
  routes { Hyrax::Engine.routes }

  describe "#index" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    context 'with existing featured researcher' do
      let!(:frodo) { ContentBlock.create!(name: ContentBlock::NAME_REGISTRY[:researcher], value: 'Frodo Baggins', created_at: Time.zone.now) }

      it 'finds the featured researcher' do
        get :index
        expect(response).to be_successful
        expect(assigns(:featured_researcher)).to eq frodo
      end
    end

    context 'with no featured researcher' do
      it "sets featured researcher" do
        get :index
        expect(response).to be_successful
        assigns(:featured_researcher).tap do |researcher|
          expect(researcher).to be_kind_of ContentBlock
          expect(researcher.name).to eq 'featured_researcher'
        end
      end
    end

    it "sets marketing text" do
      get :index
      expect(response).to be_successful
      assigns(:marketing_text).tap do |marketing|
        expect(marketing).to be_kind_of ContentBlock
        expect(marketing.name).to eq 'marketing_text'
      end
    end

    it "includes only Work objects in recent documents" do
      get :index
      expect(assigns(:recent_documents).all?(&:work?)).to eq true
    end

    context "with a document not created this second", clean_repo: true do
      let(:work_1) { { id: 'work_1', has_model_ssim: 'Monograph', read_access_person_ssim: user.user_key, date_uploaded_dtsi: 2.days.ago.iso8601 } }
      let(:work_2) { { id: 'work_2', has_model_ssim: 'Monograph', read_access_person_ssim: user.user_key, date_uploaded_dtsi: 4.days.ago.iso8601 } }
      let(:work_3) { { id: 'work_3', has_model_ssim: 'Monograph', read_access_person_ssim: user.user_key, date_uploaded_dtsi: 3.days.ago.iso8601 } }

      before do
        [work_1, work_2, work_3].each do |obj|
          Hyrax::SolrService.add(obj)
        end
        Hyrax::SolrService.commit
      end

      it "sets recent documents in the right order" do
        get :index
        expect(response).to be_successful
        expect(assigns(:recent_documents).length).to eq 3
        create_times = assigns(:recent_documents).map { |d| d['date_uploaded_dtsi'] }
        expect(create_times).to eq create_times.sort.reverse
      end
    end

    context "with collections" do
      let(:presenter) { double }
      let(:repository) { double }
      let(:collection_results) { double(documents: ['collection results']) }

      before do
        allow(controller).to receive(:repository).and_return(repository)
        allow(controller).to receive(:search_results).and_return([nil, ['recent document']])
        allow_any_instance_of(Hyrax::CollectionsService).to receive(:search_results).and_return(collection_results.documents)
      end

      it "initializes the presenter with ability and a list of collections" do
        expect(Hyrax::HomepagePresenter).to receive(:new).with(Ability,
                                                               ["collection results"])
                                                         .and_return(presenter)
        get :index
        expect(response).to be_successful
        expect(assigns(:presenter)).to eq presenter
      end
    end

    context "with featured works" do
      let(:my_work) { valkyrie_create(:hyrax_work) }

      before do
        FeaturedWork.create!(work_id: my_work.id)
      end

      it "sets featured works" do
        get :index
        expect(response).to be_successful
        expect(assigns(:featured_work_list)).to be_kind_of FeaturedWorkList
      end
    end

    it "sets announcement content block" do
      get :index
      expect(response).to be_successful
      assigns(:announcement_text).tap do |announcement|
        expect(announcement).to be_kind_of ContentBlock
        expect(announcement.name).to eq 'announcement_text'
      end
    end

    context "without solr" do
      before do
        allow_any_instance_of(Hyrax::SearchService).to receive(:search_results).and_raise Blacklight::Exceptions::InvalidRequest
      end

      it "errors gracefully" do
        get :index
        expect(response).to be_successful
        expect(assigns(:admin_sets)).to be_blank
        expect(assigns(:recent_documents)).to be_blank
      end
    end
  end
end
