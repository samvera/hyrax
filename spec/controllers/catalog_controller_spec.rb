require 'spec_helper'

describe CatalogController do
  before do
    ActiveFedora::Base.delete_all
  end

  describe "when logged in" do
    let(:user) { FactoryGirl.create(:user) }
    let!(:work1) { FactoryGirl.create(:public_generic_work, user: user) }
    let!(:work2) { FactoryGirl.create(:public_generic_work) }
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
        get 'index', works: 'mine', 'f' => {'generic_type_sim' => 'Work'}
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
    let(:manager_user) { FactoryGirl.create(:user) }
    let!(:work1) { FactoryGirl.create(:generic_work, user: creating_user) }
    let!(:work2) { FactoryGirl.create(:embargoed_work, user: creating_user) }

    before do
      allow_any_instance_of(User).to receive(:groups).and_return(['admin'])
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
