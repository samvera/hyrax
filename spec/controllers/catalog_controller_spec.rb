require 'spec_helper'

describe CatalogController do
  before do
    ActiveFedora::Base.delete_all
  end

  describe "when logged in" do
    let(:user) { FactoryGirl.create(:user) }
    let!(:work1) { FactoryGirl.create(:generic_work, user: user) }
    let!(:work2) { FactoryGirl.create(:generic_work) }
    before do
      sign_in user
    end
    context "Searching all works" do
      it "should return all the works" do
        get 'index', 'f' => {'generic_type_sim' => 'Work'}
        response.should be_successful
        assigns(:document_list).map(&:id).should == [work1.id, work2.id]
      end
    end

    context "searching just my works" do
      it "should return just my works" do
        get 'index', works: 'mine'
        response.should be_successful
        assigns(:document_list).map(&:id).should == [work1.id]
      end
    end

    context "when json is requested for autosuggest of related works" do
      let!(:work) { FactoryGirl.create(:generic_work, user: user, title:"All my #{srand}") }
      it "should return json" do
        xhr :get, :index, format: :json, q: work.title
        json = JSON.parse(response.body)
        # Grab the doc corresponding to work and inspect the json
        work_json = json["docs"].first
        work_json.should == {"pid"=>work.pid, "title"=> "#{work.title} (#{work.human_readable_type})"}
      end
    end

  end

  describe "when logged in as a repository manager" do
    let(:creating_user) { FactoryGirl.create(:user) }
    let(:email) { 'manager@example.com' }
    let(:manager_user) { FactoryGirl.create(:user, email: email) }
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    let!(:work1) {
      FactoryGirl.create_curation_concern(:generic_work, creating_user, { visibility: visibility })
    }
    let(:embargo) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    let(:embargo_release_date) { Date.tomorrow.to_s }
    let!(:work2) {
      FactoryGirl.create_curation_concern(:generic_work, creating_user, { visibility: embargo, embargo_release_date: embargo_release_date })
    }
    before do
      sign_in manager_user
    end
    context "searching all works" do
      it "should return other users' private works" do
        get 'index', 'f' => {'generic_type_sim' => 'Work'}
        response.should be_successful
        assigns(:document_list).map(&:id).should include(work1.id)
      end
      it "should return other users' embargoed works" do
        get 'index', 'f' => {'generic_type_sim' => 'Work'}
        response.should be_successful
        assigns(:document_list).map(&:id).should include(work2.id)
      end
    end

  end
end
