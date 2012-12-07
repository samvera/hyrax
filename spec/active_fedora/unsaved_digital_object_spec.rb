# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe ActiveFedora::UnsavedDigitalObject do
  it "should have an ARK-style pid" do    
    @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'id')
    @obj.save
    Sufia::IdService.valid?(@obj.pid).should be_true
  end
  it "should not use Fedora's pid service" do
    ActiveFedora::RubydoraConnection.any_instance.should_receive(:nextid).never
    @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'id')
    @obj.save
  end
  it "should allow objects to override ARK-style pid generation" do
    mock_pid = 'scholarsphere:ef12ef12f'
    @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'id', mock_pid)
    @obj.pid.should == mock_pid
  end
  it "should not assign a new pid if a pid was specified at instantiation" do
    mock_pid = 'scholarsphere:ef12ef12f'
    @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'id', mock_pid)
    @obj.assign_pid
    @obj.pid.should == mock_pid
  end
  it "should not assign a pid that already exists in Fedora" do
    mock_pid = 'scholarsphere:ef12ef12f'
    unique_pid = 'scholarsphere:bb22bb22b'
    Sufia::IdService.stub(:next_id).and_return(mock_pid, unique_pid)
    ActiveFedora::Base.stub(:exists?).with(mock_pid).and_return(true)
    ActiveFedora::Base.stub(:exists?).with(unique_pid).and_return(false)
    @obj = ActiveFedora::UnsavedDigitalObject.new(ActiveFedora::Base, 'id')
    pid = @obj.assign_pid
    @obj.pid.should == unique_pid
  end
end
