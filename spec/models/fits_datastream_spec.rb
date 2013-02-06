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

describe FitsDatastream do
  before(:all) do
    @file = GenericFile.new
    @file.add_file_datastream(File.new(fixture_path + '/world.png'), :dsid=>'content')
    @file.apply_depositor_metadata('mjg36')
    @file.save
    @file = GenericFile.find(@file.pid)
  end
  after(:all) do
    @file.delete
  end
  it "should have a format label" do
    @file.format_label.should == ["Portable Network Graphics"]
  end
  it "should have a mime type" do
    @file.mime_type.should == "image/png"
  end
  it "should have a file size" do
    @file.file_size.should == ["4218"]
  end
  it "should have a last modified timestamp" do
    @file.last_modified.should_not be_empty
  end
  it "should have a filename" do
    @file.filename.should_not be_empty
  end
  it "should have a checksum" do
    @file.original_checksum.should == ["28da6259ae5707c68708192a40b3e85c"]
  end
end

