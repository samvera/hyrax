require 'spec_helper'

describe Hydra::Controller::RepositoryControllerBehavior do
  before(:all) do
    class RepositoryControllerTest < ApplicationController
      include Hydra::Controller::RepositoryControllerBehavior
    end
  end

  subject { RepositoryControllerTest.new }
  
  describe "load_document" do
    it "should load the model for the pid" do
      Deprecation.stub(:warn)
      mock_model = mock("model")
      subject.stub(:params).and_return( {:id => "object id"} )
      ActiveFedora::Base.should_receive(:find).with("object id", :cast=>true).and_return(mock_model)
      subject.send(:load_document).should == mock_model
    end
  end
  
  describe "format_pid" do
    it "convert pids into XHTML safe strings" do 
     Deprecation.stub(:warn)
     pid = subject.format_pid("hydra:123")
     pid.should match(/hydra_123/)   
    end 
  end
  
end
