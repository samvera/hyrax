require 'spec_helper'


# See cucumber tests (ie. /features/edit_document.feature) for more tests, including ones that test the edit method & view
# You can run the cucumber tests with 
#
# cucumber --tags @edit
# or
# rake cucumber

describe Hydra::AssetsController do
  before :all do
    @behavior = Hydra::AssetsController.deprecation_behavior
    Hydra::AssetsController.deprecation_behavior = :silence
  end

  after :all do
    Hydra::AssetsController.deprecation_behavior = @behavior 
  end
  
  before do
      @user = FactoryGirl.create(:user)
      sign_in @user
      controller.stub(:enforce_access_controls).and_return(true)
  end
  
  it "should use DocumentController" do
    controller.should be_an_instance_of(Hydra::AssetsController)
  end

  describe "new" do
    before do
      @user = FactoryGirl.create(:user)
      sign_in @user
      @asset = ModsAsset.new
      ModsAsset.stub(:new).and_return(@asset)
    end
    it "should create and redirect with a flash message" do
      get :new, :content_type=>'mods_asset'
      response.should redirect_to edit_catalog_path(@asset, :new_asset=>true)
      flash[:notice].should == "Created a Mods Asset with pid #{@asset.pid}. Now it's ready to be edited."
    end
  end
  
  describe "update" do
    it "should update the object with the attributes provided" do
      mock_document = ModsAsset.new
      mock_document.stub(:pid => '_PID_')
      mock_document.stub(:update_from_computing_id).and_return(nil)
      controller.should_receive(:check_embargo_date_format).and_return(nil)

      ModsAsset.should_receive(:find).with("_PID_").and_return(mock_document)
      
      simple_request_params = {"asset"=>{
          "descMetadata"=>{
            "subject"=>{"0"=>"subject1", "1"=>"subject2", "2"=>"subject3"}
          }
        }
      }
      
      mock_document.should_receive(:update_datastream_attributes).with("descMetadata"=>{"subject"=>{"0"=>"subject1", "1"=>"subject2", "2"=>"subject3"}}).and_return({"subject"=>{"2"=>"My Topic"}})
      mock_document.should_receive(:save)
      controller.stub(:display_release_status_notice)
      put :update, {:id=>"_PID_"}.merge(simple_request_params)

      response.should redirect_to catalog_path(mock_document.pid, :viewing_context=>"browse")

    end
    
    it "should support updating OM::XML datastreams" do
      mock_document = ModsAsset.new
      mock_document.stub(:pid => '_PID_')
      mock_document.stub(:update_from_computing_id).and_return(nil)
      ModsAsset.should_receive(:find).with("_PID_").and_return(mock_document)
      
      update_method_args = [ "descMetadata" => { [{:person=>0}, :role] => {"0"=>"role1","1"=>"role2","2"=>"role3"} } ]
      mock_document.should_receive(:update_datastream_attributes).with( *update_method_args ).and_return({"person_0_role"=>{"0"=>"role1","1"=>"role2","2"=>"role3"}})
      mock_document.should_receive(:save)
      
      
      nokogiri_request_params = {
        "id"=>"_PID_", 
        "content_type"=>"mods_asset",
        "field_selectors"=>{
          "descMetadata"=>{
            "person_0_role"=>[{":person"=>"0"}, "role"]
          }
        }, 
        "asset"=>{
          "descMetadata"=>{
            "person_0_role"=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"}
          }
        }
      }
      controller.stub(:display_release_status_notice)
      put :update, nokogiri_request_params
      # put :update, :id=>"_PID_", "content_type"=>"mods_asset", "datastream"=>"descMetadata", "field_name"=>"person_0_last_name","parent_select"=>[{":person"=>"0"}, ":last_name"], "child_index"=>"0", "value"=>"Sample New Value"
      response.should redirect_to edit_catalog_path(mock_document.pid, :wf_step=>"publication")
    end
    
    it "should handle complete updates of many fields in many datastreams" do
      pending("This is failing intermittently. See https://jira.duraspace.org/browse/HYDRUS-166 for more info")
      request_params = {"id"=>"hydrangea:fixture_mods_article3", "content_type"=>"mods_asset", "action"=>"update", "_method"=>"put"}
      request_params["field_selectors"] = {"descMetadata"=>{"person_0_computing_id"=>[{"person"=>"0"}, "computing_id"], "journal_0_issue_start_page"=>[{"journal"=>"0"}, "issue", "start_page"], "person_1_description"=>[{"person"=>"1"}, "description"], "person_1_institution"=>[{"person"=>"1"}, "institution"], "journal_0_origin_info_publisher"=>[{"journal"=>"0"}, "origin_info", "publisher"], "abstract"=>["abstract"], "person_0_last_name"=>[{"person"=>"0"}, "last_name"], "person_0_description"=>[{"person"=>"0"}, "description"], "journal_0_issue_volume"=>[{"journal"=>"0"}, "issue", "volume"], "title_info_main_title"=>["title_info", "main_title"], "location_url"=>["location", "url"], "note"=>["note"], "person_1_last_name"=>[{"person"=>"1"}, "last_name"], "subject_topic"=>["subject", "topic"], "person_0_institution"=>[{"person"=>"0"}, "institution"], "person_1_first_name"=>[{"person"=>"1"}, "first_name"], "person_1"=>[{"person"=>"1"}], "journal_0_title_info_main_title"=>[{"journal"=>"0"}, "title_info", "main_title"], "journal_0_issue_level"=>[{"journal"=>"0"}, "issue", "level"], "journal_0_issue_end_page"=>[{"journal"=>"0"}, "issue", "end_page"], "peer_reviewed"=>["peer_reviewed"], "person_0_first_name"=>[{"person"=>"0"}, "first_name"], "person_1_computing_id"=>[{"person"=>"1"}, "computing_id"], "journal_0_issn"=>[{"journal"=>"0"}, "issn"], "journal_0_issue_publication_date"=>[{"journal"=>"0"}, "issue", "publication_date"]}, "rightsMetadata"=>{"embargo_embargo_release_date"=>["embargo", "embargo_release_date"]}, "properties"=>{"release_to"=>["release_to"]}} 
      request_params["asset"] = {"descMetadata"=>{"person_0_computing_id"=>{"0"=>""}, "journal_0_issue_start_page"=>{"0"=>"195"}, "person_1_description"=>{"0"=>""}, "person_1_institution"=>{"0"=>"Baltimore"}, "journal_0_origin_info_publisher"=>{"0"=>"PUBLISHER"}, "abstract"=>{"0"=>"ABSTRACT"}, "person_0_last_name"=>{"0"=>"Smith"}, "person_0_description"=>{"0"=>""}, "journal_0_issue_volume"=>{"0"=>"2               "}, "title_info_main_title"=>{"0"=>"Test Article"}, "location_url"=>{"0"=>"http://example.com/foo"}, "note"=>{"0"=>""}, "person_1_last_name"=>{"0"=>"Lacks"}, "subject_topic"=>{"0"=>"TOPIC 1", "1"=>"TOPIC 2", "2"=>"CONTROLLED TERM"}, "person_0_institution"=>{"0"=>"FACULTY, UNIVERSITY"}, "person_1_first_name"=>{"0"=>"Henrietta"}, "journal_0_title_info_main_title"=>{"0"=>"The Journal of Mock Object"}, "journal_0_issue_level"=>{"0"=>""}, "journal_0_issue_end_page"=>{"0"=>"230"}, "person_0_first_name"=>{"0"=>"John"}, "person_1_computing_id"=>{"0"=>""}, "journal_0_issn"=>{"0"=>"1234-5678"}, "journal_0_issue_publication_date"=>{"0"=>"FEB. 2007"}}, "rightsMetadata"=>{"embargo_embargo_release_date"=>{"0"=>""}}, "properties"=>{"released"=>{"0"=>"true"}, "release_to"=>{"0"=>"public"}}}
      expected_response = {"descMetadata"=>{"journal_0_issue_start_page"=>{"0"=>"195"}, "person_0_computing_id"=>{"-1"=>""}, "abstract"=>{"0"=>"ABSTRACT"}, "journal_0_origin_info_publisher"=>{"0"=>"PUBLISHER"}, "person_1_description"=>{"-1"=>""}, "person_1_institution"=>{"0"=>"Baltimore"}, "journal_0_issue_volume"=>{"0"=>"2               "}, "person_0_description"=>{"-1"=>""}, "person_0_last_name"=>{"0"=>"Smith"}, "title_info_main_title"=>{"0"=>"Test Article"}, "note"=>{"-1"=>""}, "location_url"=>{"0"=>"http://example.com/foo"}, "person_1_last_name"=>{"0"=>"Lacks"}, "subject_topic"=>{"0"=>"TOPIC 1", "1"=>"TOPIC 2", "2"=>"CONTROLLED TERM"}, "journal_0_issue_end_page"=>{"0"=>"230"}, "journal_0_title_info_main_title"=>{"0"=>"The Journal of Mock Object"}, "journal_0_issue_level"=>{"-1"=>""}, "person_1_first_name"=>{"0"=>"Henrietta"}, "person_0_institution"=>{"0"=>"FACULTY, UNIVERSITY"}, "journal_0_issn"=>{"0"=>"1234-5678"}, "person_0_first_name"=>{"0"=>"John"}, "person_1_computing_id"=>{"-1"=>""}, "journal_0_issue_publication_date"=>{"0"=>"FEB. 2007"}}, "rightsMetadata"=>{"embargo_embargo_release_date"=>{"-1"=>""}}, "properties"=>{:released=>{"0"=>"true"}, [:release_to]=>{}, :release_to=>{"0"=>"public"}}}
      
      post :update, request_params
      expected_response.each_pair do |datastream_name, fields|
        fields.each_pair do |field_pointer, value|
          assigns[:response][datastream_name][field_pointer].should == value
        end
      end  
    end
  end
  
  describe "destroy" do
    it "should delete the asset identified by pid" do
      mock_obj = double("asset")
      mock_obj.should_receive(:delete)
      mock_obj.should_receive(:destroy_child_assets).and_return([])
      ActiveFedora::Base.should_receive(:find).with("__PID__", :cast=>true).and_return(mock_obj)
      delete(:destroy, :id => "__PID__")
    end
  end
  
  # withdraw is a conditional destroy, with the conditions dependant on the project requirements.
  # Currently, the widthdraw method is an alias for destroy, should behave as such
  describe "withdraw" do
    it "should withdraw the asset identified by pid" do
      mock_obj = double("asset")
      mock_obj.should_receive(:delete)
      mock_obj.should_receive(:destroy_child_assets).and_return([])
      ActiveFedora::Base.should_receive(:find).with("__PID__", :cast=>true).and_return(mock_obj)
      delete(:withdraw, :id => "__PID__")
    end
  end
  
  
   
end
