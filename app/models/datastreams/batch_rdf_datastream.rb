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

class BatchRdfDatastream < ActiveFedora::NtriplesRDFDatastream
  register_vocabularies RDF::DC
  map_predicates do |map|
    map.part(:to => "hasPart", :in => RDF::DC)
    map.creator(:to => "creator", :in => RDF::DC)
    map.title(:to => "title", :in => RDF::DC)
    map.status(:to => "type", :in => RDF::DC)
  end
end

