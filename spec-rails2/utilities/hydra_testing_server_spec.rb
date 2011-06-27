require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
# require File.expand_path(File.dirname(__FILE__) + '/../../lib/hydra/hydra_testing_server.rb')

describe Hydra::TestingServer do
  
  it "should be configurable with params hash" do
    jetty_params = {
      :quiet => false,
      :jetty_home => "/path/to/jetty",
      :jetty_port => 8888,
      :solr_home => '/path/to/solr',
      :fedora_home => '/path/to/fedora'
    }
    
    ts = Hydra::TestingServer.configure(jetty_params) 
    ts.quiet.should == false
    ts.jetty_home.should == "/path/to/jetty"
    ts.port.should == 8888
    ts.solr_home.should == '/path/to/solr'
    ts.fedora_home.should == '/path/to/fedora'
  end
  
  it "should be configurable with default values" do
    ts = Hydra::TestingServer.configure 
    ts.quiet.should == true
    ts.jetty_home.should == File.join(RAILS_ROOT, "jetty")
    ts.port.should == 8888
    ts.solr_home.should == File.join(ts.jetty_home, "solr" )
    ts.fedora_home.should == File.join(ts.jetty_home, "fedora","default")
  end
  
  it "should override nil params with defaults" do
    jetty_params = {
      :quiet => false,
      :jetty_home => nil,
      :jetty_port => 8888,
      :solr_home => '/path/to/solr',
      :fedora_home => nil
    }
    
    ts = Hydra::TestingServer.configure(jetty_params) 
    ts.quiet.should == false
    ts.jetty_home.should == File.join(RAILS_ROOT, "jetty")
    ts.port.should == 8888
    ts.solr_home.should == "/path/to/solr"
    ts.fedora_home.should == File.join(ts.jetty_home, "fedora","default")
  end
  
end