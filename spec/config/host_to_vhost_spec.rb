require 'spec_helper'

describe 'host_to_vhost' do
  it "should return the proper vhost on fedora1test" do
    Socket.stubs(:gethostname).returns('fedora1test')
    ScholarSphere::Application.get_vhost_by_host[0].should == 'scholarsphere-integration.dlt.psu.edu-8443'
    ScholarSphere::Application.get_vhost_by_host[1].should == 'https://scholarsphere-integration.dlt.psu.edu:8443/'
  end
  it "should return the proper vhost on fedora2test" do
    Socket.stubs(:gethostname).returns('fedora2test')
    ScholarSphere::Application.get_vhost_by_host[0].should == 'scholarsphere-test.dlt.psu.edu'
    ScholarSphere::Application.get_vhost_by_host[1].should == 'https://scholarsphere-test.dlt.psu.edu/'
  end
  it "should return the proper vhost on ss1stage" do
    Socket.stubs(:gethostname).returns('ss1stage')
    ScholarSphere::Application.get_vhost_by_host[0].should == 'scholarsphere-staging.dlt.psu.edu'
    ScholarSphere::Application.get_vhost_by_host[1].should == 'https://scholarsphere-staging.dlt.psu.edu/'
  end
  it "should return the proper vhost on dev" do
    Socket.stubs(:gethostname).returns('some1host')
    ScholarSphere::Application.get_vhost_by_host[0].should == 'some1host'
    ScholarSphere::Application.get_vhost_by_host[1].should == 'https://some1host/'
  end
end
