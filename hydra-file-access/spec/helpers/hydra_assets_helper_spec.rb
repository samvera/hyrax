require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HydraAssetsHelper do
  before :all do
    @behavior = Hydra::HydraAssetsHelperBehavior.deprecation_behavior
    Hydra::HydraAssetsHelperBehavior.deprecation_behavior = :silence
  end

  after :all do
    Hydra::HydraAssetsHelperBehavior.deprecation_behavior = @behavior
  end
  include HydraAssetsHelper
  
  describe "link_to_create_asset" do
    it "should generate login links with redirect params if user is not logged in" do
      helper.should_receive(:current_user).and_return User.new
      helper.link_to_create_asset("Create a foo", "foo_model").should == "<a href=\"/hydra/assets/new?content_type=foo_model\" class=\"create_asset\">Create a foo</a>"
    end
    it "should generate login links with redirect params if user is not logged in" do
      helper.should_receive(:current_user).and_return false
      # rails 3.1.x
      # helper.link_to_create_asset("Create a foo", "foo_model").should == "<a href=\"/users/sign_in?redirect_params%5Baction%5D=new&amp;redirect_params%5Bcontent_type%5D=foo_model&amp;redirect_params%5Bcontroller%5D=assets\" class=\"create_asset\">Create a foo</a>"      
      # rails 3.0.x
      helper.link_to_create_asset("Create a foo", "foo_model").should == "<a href=\"/users/sign_in?redirect_params%5Baction%5D=new&amp;redirect_params%5Bcontent_type%5D=foo_model&amp;redirect_params%5Bcontroller%5D=assets\" class=\"create_asset\">Create a foo</a>"      
    end
  end
  
  describe "delete_asset_link" do
    it "should generate a delete link and confirmation dialog" do
      generated_html = helper.delete_asset_link("__PID__", "whizbang")
                                          # "a.delete_asset[href='/catalog/__PID__/delete']", :content=> "Delete this whizbang" 
      generated_html.should have_selector "a.delete_asset_link[href='/catalog/__PID__/delete']", :content=> "Delete this whizbang" 
      generated_html.should be_html_safe
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
    describe "with outbound has_part" do
      before do
        @asset_object4 =ModsAsset.new
        @file_object1 = ModsAsset.create
        @asset_object4.add_relationship(:has_part,@file_object1)
        @asset_object4.save
      end
      after do
        @asset_object4.delete
        @file_object1.delete
      end
      it "should find one" do
        #outbound has_part
        doc = ModsAsset.find_by_solr(@asset_object4.pid).first
        get_file_asset_count(doc).should == 1
      end
    end

    describe "with has_part and inbound is_part_of" do
      before do
        @asset_object5 =ModsAsset.create
        @file_object1 = FileAsset.create
        @file_object2 = FileAsset.create
        @file_object2.container = @asset_object5
        @asset_object5.add_relationship(:has_part,@file_object1)
        @asset_object5.save
        @file_object2.save
      end
      after do
        @asset_object5.delete
        @file_object1.delete
        @file_object2.delete
      end
      it "should find two" do
        doc = ActiveFedora::Base.find_by_solr(@asset_object5.pid).first
        get_file_asset_count(doc).should == 2
      end
    end

    describe "with inbound is_part_of" do
      before do
        @asset_object6 =ModsAsset.create
        @file_object1 = FileAsset.create
        @file_object1.container = @asset_object6
        @asset_object6.save
        @file_object1.save
      end
      after do
        @asset_object6.delete
        @file_object1.delete
      end
      it "should find one" do
        doc = ActiveFedora::Base.find_by_solr(@asset_object6.pid).first
        get_file_asset_count(doc).should == 1
      end
    end

    describe "with inbound is_part_of" do
      before do
        @asset_object7 =ModsAsset.create
      end
      after do
        @asset_object7.delete
      end
      it "should find zero" do
        doc = ActiveFedora::Base.find_by_solr(@asset_object7.pid).first
        get_file_asset_count(doc).should == 0
      end
    end
  end

end
