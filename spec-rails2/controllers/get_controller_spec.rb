require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'mocha'

# See cucumber tests (ie. /features/edit_document.feature) for more tests, including ones that test the edit method & view
# You can run the cucumber tests with 
#
# cucumber --tags @edit
# or
# rake cucumber

describe GetController do
  
  before do
    #controller.stubs(:protect_from_forgery).returns("meh")
    session[:user]='bob'
  end
  
  it "should use DownloadsController" do
    controller.should be_an_instance_of(GetController)
  end
  
  it "should be restful" do
    #route_for(:controller=>'courses', :action=>'index').should == '/'
    route_for(:controller=>'get', :action=>'show', :id=>"_PID_").should == '/get/_PID_'
    route_for(:controller=>'get', :action=>'show', :id=>"_PID_", :format=>"pdf").should == '/get/_PID_.pdf'
    route_for(:controller=>'get', :action=>'show', :id=>"_PID_", :format=>"jp2").should == '/get/_PID_.jp2'

    params_from(:get, '/get/_PID_').should == {:controller=>'get', :id=>"_PID_", :action=>'show'}
    params_from(:get, '/get/_PID_.pdf').should == {:controller=>'get', :format=>"pdf", :id=>"_PID_", :action=>'show'}
    params_from(:get, '/get/_PID_.jp2').should == {:controller=>'get', :format=>"jp2", :id=>"_PID_", :action=>'show'}

  end
  
  describe "show" do
    it "should return the content of the first PDF datastream for the object identified by download_id" do
      #Fedora::Repository.any_instance.expects(:fetch_custom).with("_PID_", "datastreams/my_datastream.pdf/content").returns("foo")
      mock_ds = mock("pdf1 datastream", :label=>"first.pdf", :content=>"pdf1 content", :attributes=>{"mimeType"=>"application/pdf"})
      result_object = mock("result_object")
      ActiveFedora::Base.expects(:load_instance).returns(result_object)
      controller.expects(:downloadables).with(result_object, :canonical=>true).returns(mock_ds)
      controller.expects(:send_data).with("pdf1 content", :filename=>"first.pdf", :type => "application/pdf") #.returns("foo")
      get :show, :id=>"_PID_"
    end
    
    it "should return canonical pdf as response to .pdf requests" do
      result_object = mock("result_object")
      ActiveFedora::Base.expects(:load_instance).returns(result_object)
      mock_ds = mock("pdf1 datastream", :label=>"first.pdf", :content=>"pdf1 content", :attributes=>{"mimeType"=>"application/pdf"})
      
      controller.expects(:downloadables).with(result_object, :canonical=>true, :mime_type=>"application/pdf").returns(mock_ds)
      controller.expects(:send_data).with("pdf1 content", :filename=>"first.pdf", :type => "application/pdf") #.returns("foo")
      get :show, :id=>"_PID_", :format=>"pdf"
    end
    it "should return canonical jpeg2000 as response to .jp2 requests" do
      result_object = mock("result_object")
      ActiveFedora::Base.expects(:load_instance).returns(result_object)
      mock_ds = mock("jp2 datastream", :label=>"first.jp2", :content=>"jp2 content", :url=>"jp2_url", :attributes=>{"mimeType"=>"image/jp2"})
      
      controller.expects(:downloadables).with(result_object, :canonical=>true, :mime_type=>"image/jp2").returns(mock_ds)
      controller.expects(:send_data).with("jp2 content", :filename=>"first.jp2", :type => "image/jp2") #.returns("foo")
      get :show, :id=>"_PID_", :format=>"jp2"
    end
    it "should support using djatoka with canonical jpeg2000" do
      result_object = mock("result_object")
      ActiveFedora::Base.expects(:load_instance).returns(result_object)
      mock_ds = mock("jp2 datastream", :url=>"mock_jp2_url")
            
      controller.expects(:downloadables).with(result_object, :canonical=>true, :mime_type=>"image/jp2").returns(mock_ds)
      Djatoka.expects(:get_image).returns("djatoka result")
      controller.expects(:send_data).with( "djatoka result", :type=>"image/jpeg"  )
      get :show, :id=>"_PID_", :format=>"jp2", :image_server=>"true"
    end
    it "should support using djatoka with canonical jpeg2000" do
      result_object = mock("result_object")
      ActiveFedora::Base.expects(:load_instance).returns(result_object)
      mock_ds = mock("jp2 datastream", :url=>"mock_jp2_url")
      
      controller.expects(:downloadables).with(result_object, :canonical=>true, :mime_type=>"image/jp2").returns(mock_ds)
      Djatoka.expects(:scale).with("mock_jp2_url/content", "96").returns("djatoka result")
      controller.expects(:send_data).with( "djatoka result", :type=>"image/jpeg" )
      get :show, :id=>"_PID_", :format=>"jp2", :image_server=>{:scale=>"96"}
    end
  end
  
  
end