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

# properties datastream: catch-all for info that didn't have another home.  Particularly depositor.
class PropertiesDatastream < ActiveFedora::OmDatastream
  set_terminology do |t|
    t.root(:path=>"fields" ) 
    # This is where we put the user id of the object depositor -- impacts permissions/access controls
    t.depositor :index_as=>[:stored_searchable]
    # This is where we put the relative path of the file if submitted as a folder
    t.relative_path

    t.proxy_depositor path: 'proxyDepositor', :index_as=>:symbol
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.fields
    end
    builder.doc
  end
end
