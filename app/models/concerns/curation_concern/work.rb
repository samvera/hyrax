module CurationConcern::Work
  extend ActiveSupport::Concern
  
  included do
    include ::CurationConcern::Curatable
    include ::CurationConcern::WithGenericFiles
    include Hydra::AccessControls::Permissions
    include ::CurationConcern::Embargoable
    include ::CurationConcern::WithEditors
    include CurationConcern::WithLinkedResources

    # Modules in Curate's CurationConcern::Work that we _might_ pull in later
    # include Curate::ActiveModelAdaptor
    # include CurationConcern::WithLinkedContributors
    # include CurationConcern::WithRelatedWorks
    
    attr_accessor :files
  end
end