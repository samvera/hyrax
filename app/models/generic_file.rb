class GenericFile < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods

  has_metadata :name => "characterization", :type => FitsDatastream
  has_metadata :name => "descMetadata", :type => Psu::DcDatastream

  self.ds_specs['content']= {:type=>FileContentDatastream, :label=>"", :label=>"Fedora Object-to-Object Relationship Metadata", :control_group=>'X', :block=>nil}

  
#  def check_content_for_
end
