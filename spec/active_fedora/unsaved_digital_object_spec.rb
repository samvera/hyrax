require 'spec_helper'

describe ActiveFedora::UnsavedDigitalObject do
  it "should have an ARK-style pid" do    
    @obj = ActiveFedora::UnsavedDigitalObject.new(self.class, '')
    @obj.save
    PSU::IdService.valid?(@obj.pid).should be_true
  end
  it "should not use Fedora's pid service" do
    ActiveFedora::RubydoraConnection.any_instance.expects(:nextid).never
    @obj = ActiveFedora::UnsavedDigitalObject.new(self.class, '')
    @obj.save
  end
  it "should allow objects to override ARK-style pid generation" do
    mock_pid = 'id:ef12ef12f'
    @obj = ActiveFedora::UnsavedDigitalObject.new(self.class, '', mock_pid)
    @obj.pid.should == mock_pid
  end
  it "should not assign a new pid if a pid was specified at instantiation" do
    mock_pid = 'id:ef12ef12f'
    @obj = ActiveFedora::UnsavedDigitalObject.new(self.class, '', mock_pid)
    @obj.assign_pid
    @obj.pid.should == mock_pid
  end
  it "should not assign a pid that already exists in Fedora" do
    mock_pid = 'id:ef12ef12f'
    unique_pid = 'id:bb22bb22b'
    PSU::IdService.stubs(:mint).returns(mock_pid, unique_pid)
    ActiveFedora::Base.stubs(:find).with(mock_pid).returns(true)
    ActiveFedora::Base.stubs(:find).with(unique_pid).returns(nil)
    @obj = ActiveFedora::UnsavedDigitalObject.new(self.class, '')
    pid = @obj.assign_pid
    @obj.pid.should == unique_pid
  end
end
