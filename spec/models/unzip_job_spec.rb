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

describe UnzipJob do
  before(:all) do
    @batch = Batch.create
    GenericFile.any_instance.stub(:terms_of_service).and_return('1')
    @generic_file = GenericFile.new(:batch=>@batch)
    @generic_file.add_file_datastream(File.new(fixture_path + '/icons.zip'), :dsid=>'content')
    @generic_file.apply_depositor_metadata('mjg36')
    @generic_file.save
  end

  after(:all) do
    @batch.delete
    @generic_file.delete
  end

  it "should create GenericFiles for each file in the zipfile" do
    one = GenericFile.new
    #one.should_receive(:characterize_if_changed)
    two = GenericFile.new
    #two.should_receive(:characterize_if_changed)
    three = GenericFile.new
    #three.should_receive(:characterize_if_changed)
    GenericFile.should_receive(:new).exactly(3).times.and_return(one, two, three)
    Resque.enqueue(UnzipJob, @generic_file.pid)

    one.content.size.should == 13024 #bread
    one.content.label.should == 'spec/fixtures/bread-icon.png'
    one.content.mimeType.should == 'image/png'
    one.batch.should == @batch

    two.content.size.should == 12995 #coffee
    two.content.label.should == 'spec/fixtures/coffeecup-red-icon.png'
    two.content.mimeType.should == 'image/png'
    two.batch.should == @batch

    three.content.size.should == 58097 #hamburger
    three.content.label.should == 'spec/fixtures/hamburger-icon.png'
    three.content.mimeType.should == 'image/png'
    three.batch.should == @batch

    one.delete
    two.delete
    three.delete
  end
end
