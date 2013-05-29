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

require 'datastreams/batch_rdf_datastream'

class Batch < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata
  include Sufia::ModelMethods
  include Sufia::Noid

  has_metadata :name => "descMetadata", :type => BatchRdfDatastream

  belongs_to :user, :property => "creator"
  has_many :generic_files, :property => :is_part_of

  delegate :title, :to => :descMetadata
  delegate :creator, :to => :descMetadata
  delegate :part, :to => :descMetadata
  delegate :status, :to => :descMetadata

  def self.find_or_create(pid)
    begin
      Batch.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      Batch.create({pid: pid})
    end
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)] = noid
    return solr_doc
  end
end
