require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HydraAssetsHelper do
  include HydraAssetsHelper
  
  describe "link_to_create_asset" do
    it "should generate login links with redirect params if user is not logged in" do
      helper.expects(:current_user).returns User.new
      helper.link_to_create_asset("Create a foo", "foo_model").should == "<a href=\"/assets/new?content_type=foo_model\" class=\"create_asset\">Create a foo</a>"
    end
    it "should generate login links with redirect params if user is not logged in" do
      helper.expects(:current_user).returns false
      helper.link_to_create_asset("Create a foo", "foo_model").should == "<a href=\"/user_sessions/new?redirect_params%5Baction%5D=new&amp;redirect_params%5Bcontent_type%5D=foo_model&amp;redirect_params%5Bcontroller%5D=assets\" class=\"create_asset\">Create a foo</a>"      
    end
  end
  
  describe "delete_asset_link" do
    it "should generate a delete link and confirmation dialog" do
      generated_html = helper.delete_asset_link("__PID__", "whizbang")
      generated_html.should have_tag "a#delete_asset_link[href=?]", "/catalog/__PID__/delete",  "Delete this whizbang" 
#      generated_html.should have_tag 'a.inline[href=#delete_dialog]',  "Delete this whizbang"
#      generated_html.should have_tag 'div#delete_dialog' do
#        with_tag "p", "Do you want to permanently delete this article from the repository?"
#        with_tag "form[action=?]", url_for(:action => "destroy", :controller => "assets", :id => "__PID__", :method => "delete")  do
#          with_tag "input[type=hidden][name=_method][value=delete]"
#          with_tag "input[type=submit]"
#        end
#      end
    end
  end

  describe "get_person_from_role" do
    before(:all) do
      @single_person_doc = {"person_0_role_t" => ["creator"], "person_0_first_name_t" => "GIVEN NAME", "person_0_last_name_t" => "FAMILY NAME"}
      @multiple_persons_doc = {"person_0_role_t" => ["contributor","owner"], "person_0_first_name_t" => "CONTRIBUTOR GIVEN NAME", "person_0_last_name_t" => "CONTRIBUTOR FAMILY NAME",
                               "person_1_role_t" => ["creator"], "person_1_first_name_t" => "CREATOR GIVEN NAME", "person_1_last_name_t" => "CREATOR FAMILY NAME"}
     end
     it "should return the appropriate  when 1 is available" do
       person = get_person_from_role(@single_person_doc,"creator")
       person[:first].should == "GIVEN NAME" and
       person[:last].should == "FAMILY NAME"
     end
     it "should return the appririate person when there is multiple users" do
       person = get_person_from_role(@multiple_persons_doc,"creator")
       person[:first].should == "CREATOR GIVEN NAME" and
       person[:last].should == "CREATOR FAMILY NAME"
     end
     it "should return the appropriate person when they have multiple roles" do
       person = get_person_from_role(@multiple_persons_doc,"owner")
       person[:first].should == "CONTRIBUTOR GIVEN NAME" and 
       person[:last].should == "CONTRIBUTOR FAMILY NAME"
     end
     it "should return nil when there is no user for the given role" do
       get_person_from_role(@multiple_persons_doc,"bad_role").should be_nil
     end
  end

  describe "get_file_asset_count" do
    before(:each) do
      #setup objects for following cases
      #
      #outbound has_collection_member
      #outbound has_collection_member + inbound is_part_of
      #outbound has_collection_member + outbound has_part + inbound is_part_of
      #outbound has_part
      #outbound has_part + inbound is_part_of
      #inbound is_part_of
      #none      
      @asset_object1 = ActiveFedora::Base.new
      @asset_object2 = ActiveFedora::Base.new
      @asset_object3 = ActiveFedora::Base.new
      @asset_object4 = ActiveFedora::Base.new
      @asset_object5 = ActiveFedora::Base.new
      @asset_object6 = ActiveFedora::Base.new
      @asset_object7 = ActiveFedora::Base.new
      @file_object1 = ActiveFedora::Base.new
      @file_object2 = ActiveFedora::Base.new
      @file_object3 = ActiveFedora::Base.new
      @file_object4 = ActiveFedora::Base.new

      @asset_object1.collection_members_append(@file_object1)
      @asset_object1.collection_members_append(@file_object2)

      @asset_object2.collection_members_append(@file_object1)
      @asset_object2.collection_members_append(@file_object2)
      @asset_object2.add_relationship(:has_part,@file_object3)

      @asset_object3.collection_members_append(@file_object1)
      @asset_object3.collection_members_append(@file_object2)
      @asset_object3.add_relationship(:has_part,@file_object3)
      @file_object4.part_of_append(@asset_object3)

      @asset_object4.add_relationship(:has_part,@file_object1)
      @asset_object5.add_relationship(:has_part,@file_object1)
      @file_object2.part_of_append(@asset_object5)
      @file_object1.part_of_append(@asset_object6)
     
      @asset_object1.save
      @asset_object2.save
      @asset_object3.save
      @asset_object4.save
      @asset_object5.save
      @asset_object6.save
      @asset_object7.save
      @file_object1.save
      @file_object2.save
      @file_object3.save 
      @file_object4.save
    end

    after(:each) do
      begin
        @asset_object1.delete
      rescue
      end
      begin
        @asset_object2.delete
      rescue
      end
      begin
        @asset_object3.delete
      rescue
      end
      begin
        @asset_object4.delete
      rescue
      end
      begin
        @asset_object5.delete
      rescue
      end
      begin
        @asset_object6.delete
      rescue
      end
      begin
        @asset_object7.delete
      rescue
      end
      begin
        @file_object1.delete
      rescue
      end
      begin
        @file_object2.delete
      rescue
      end
      begin
        @file_object3.delete
      rescue
      end
      begin
        @file_object4.delete
      rescue
      end
    end

    it "should return the correct number of assets with either has_collection_member file assets or parts" do
      
      #cases are
      #outbound has_collection_member
      #outbound has_collection_member + inbound is_part_of
      #outbound has_collection_member + outbound has_part + inbound is_part_of
      #outbound has_part
      #outbound has_part + inbound is_part_of
      #inbound is_part_of
      #none      

      result = ActiveFedora::Base.find_by_solr(@asset_object1.pid)
      doc = result.hits.first
      get_file_asset_count(doc).should == 2
      result = ActiveFedora::Base.find_by_solr(@asset_object2.pid)
      doc = result.hits.first
      get_file_asset_count(doc).should == 3
      result = ActiveFedora::Base.find_by_solr(@asset_object3.pid)
      doc = result.hits.first
      get_file_asset_count(doc).should == 4
      result = ActiveFedora::Base.find_by_solr(@asset_object4.pid)
      doc = result.hits.first
      get_file_asset_count(doc).should == 1
      result = ActiveFedora::Base.find_by_solr(@asset_object5.pid)
      doc = result.hits.first
      get_file_asset_count(doc).should == 2
      result = ActiveFedora::Base.find_by_solr(@asset_object6.pid)
      doc = result.hits.first
      get_file_asset_count(doc).should == 1

      result = ActiveFedora::Base.find_by_solr(@asset_object7.pid)
      doc = result.hits.first
      get_file_asset_count(doc).should == 0
    end
  end

end
