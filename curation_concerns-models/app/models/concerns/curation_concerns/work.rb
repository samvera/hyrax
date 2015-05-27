module CurationConcerns::Work
  extend ActiveSupport::Concern
  include ::CurationConcerns::Curatable
  include ::CurationConcerns::WithGenericFiles
  include Hydra::AccessControls::Embargoable
  include ::CurationConcerns::WithEditors

  # Modules in Curate's CurationConcerns::Work that we _might_ pull in later
  # include Curate::ActiveModelAdaptor
  # include CurationConcerns::WithLinkedContributors
  # include CurationConcerns::WithRelatedWorks

  def to_solr(solr_doc={}, opts={})
    super(solr_doc).tap do |solr_doc|
      Solrizer.set_field(solr_doc, 'generic_type', 'Work', :facetable)
    end
  end
end
