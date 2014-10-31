require 'spec_helper'

describe HomepageController, :type => :controller do
  routes { Rails.application.class.routes }

  describe "#index" do
    before :all do
      GenericFile.delete_all
      @gf1 = GenericFile.new(title:['Test Document PDF'], filename:['test.pdf'], tag:['rocks'], read_groups:['public'])
      @gf1.apply_depositor_metadata('mjg36')
      @gf1.save
      @gf2 = GenericFile.new(title:['Test Private Document'], filename:['test2.doc'], tag:['clouds'], contributor:['Contrib1'], read_groups:['private'])
      @gf2.apply_depositor_metadata('mjg36')
      @gf2.save
    end

    after :all do
      @gf1.delete
      @gf2.delete
    end

    let(:user) { FactoryGirl.find_or_create(:jill) }
    before do
      sign_in user
    end

    it "should set featured researcher" do
      get :index
      expect(response).to be_success
      assigns(:featured_researcher).tap do |researcher|
        expect(researcher).to be_kind_of ContentBlock
        expect(researcher.name).to eq 'featured_researcher'
      end
    end

    it "should set marketing text" do
      get :index
      expect(response).to be_success
      assigns(:marketing_text).tap do |marketing|
        expect(marketing).to be_kind_of ContentBlock
        expect(marketing.name).to eq 'marketing_text'
      end
    end

    it "should not include other user's private documents in recent documents" do
      get :index
      expect(response).to be_success
      titles = assigns(:recent_documents).map {|d| d['desc_metadata__title_tesim'][0]}
      expect(titles).to_not include('Test Private Document')
    end    

    context "with a document not created this second" do
      before do
        gf3 = GenericFile.new(title:['Test 3 Document'], read_groups:['public'])
        gf3.apply_depositor_metadata('mjg36')
        # stubbing to_solr so we know we have something that didn't create in the current second
        old_to_solr = gf3.method(:to_solr)
        allow(gf3).to receive(:to_solr) do
          old_to_solr.call.merge(
            Solrizer.solr_name('system_create', :stored_sortable, type: :date) => 1.day.ago.iso8601
          )
        end
        gf3.save
      end

      it "should set recent documents in the right order" do
        get :index
        expect(response).to be_success
        expect(assigns(:recent_documents).length).to be <= 4
        create_times = assigns(:recent_documents).map{|d| d['system_create_dtsi']}
        expect(create_times).to eq create_times.sort.reverse
      end
    end

    context "with featured works" do
      before do
        FeaturedWork.create!(generic_file_id: @gf1.id)
      end

      it "should set featured works" do
        get :index
        expect(response).to be_success
        expect(assigns(:featured_work_list)).to be_kind_of FeaturedWorkList
      end
    end
  end
end
