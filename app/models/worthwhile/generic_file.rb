module Worthwhile
  class GenericFile < ActiveFedora::Base
    include Sufia::ModelMethods
    include Hydra::AccessControls::Permissions
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Versions
    include Sufia::GenericFile::Audit
    include Sufia::GenericFile::MimeTypes
    include Sufia::GenericFile::Thumbnail
    include Sufia::GenericFile::Derivatives
    include Sufia::GenericFile::Metadata
    #belongs_to :batch, property: :is_part_of, class_name: 'ActiveFedora::Base'
    belongs_to :generic_work, property: :is_part_of, class_name: 'ActiveFedora::Base'
  end
end

