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
  
  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    Solrizer.set_field(solr_doc, 'generic_type', 'Work', :facetable)
    return solr_doc
  end
end
