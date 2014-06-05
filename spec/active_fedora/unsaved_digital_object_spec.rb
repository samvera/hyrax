require 'spec_helper'

describe ActiveFedora::UnsavedDigitalObject do
  it "should have an ARK-style pid" do    
    @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'id')
    @obj.save
    expect(Sufia::IdService).to be_valid(@obj.pid)
  end
  it "should not use Fedora's pid service" do
    expect_any_instance_of(ActiveFedora::RubydoraConnection).to_not receive(:nextid)
    @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'id')
    @obj.save
  end
  it "should allow objects to override ARK-style pid generation" do
    mock_pid = 'scholarsphere:ef12ef12f'
    @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'id', mock_pid)
    expect(@obj.pid).to eq mock_pid
  end
  it "should not assign a new pid if a pid was specified at instantiation" do
    mock_pid = 'scholarsphere:ef12ef12f'
    @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'id', mock_pid)
    @obj.assign_pid
    expect(@obj.pid).to eq mock_pid
  end
  it "should not assign a pid that already exists in Fedora" do
    mock_pid = 'scholarsphere:ef12ef12f'
    unique_pid = 'scholarsphere:bb22bb22b'
    allow(Sufia::IdService).to receive(:next_id).and_return(mock_pid, unique_pid)
    allow(ActiveFedora::Base).to receive(:exists?).with(mock_pid).and_return(true)
    allow(ActiveFedora::Base).to receive(:exists?).with(unique_pid).and_return(false)
    @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'id')
    pid = @obj.assign_pid
    expect(@obj.pid).to eq unique_pid
  end
end
