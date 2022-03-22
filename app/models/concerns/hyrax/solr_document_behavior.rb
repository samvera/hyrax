# frozen_string_literal: true
module Hyrax
  ##
  # @api public
  #
  # Hyrax extensions for +Blacklight+'s generated +SolrDocument+.
  #
  # @example using with +Blacklight::Solr::Document+
  #   class SolrDocument
  #     include Blacklight::Solr::Document
  #     include Hyrax::SolrDocumentBehavior
  #   end
  #
  # @see https://github.com/projectblacklight/blacklight/wiki/Understanding-Rails-and-Blacklight#models
  module SolrDocumentBehavior
    ModelWrapper = ActiveFedoraDummyModel # alias for backward compatibility

    extend ActiveSupport::Concern
    include Hydra::Works::MimeTypes
    include Hyrax::Permissions::Readable
    include Hyrax::SolrDocument::Export
    include Hyrax::SolrDocument::Characterization
    include Hyrax::SolrDocument::Metadata

    # Add a schema.org itemtype
    def itemtype
      types = resource_type || []
      ResourceTypesService.microdata_type(types.first)
    end

    def title_or_label
      return label if title.blank?
      title.join(', ')
    end

    def to_param
      id
    end

    def to_s # rubocop:disable Rails/Delegate
      title_or_label.to_s
    end

    ##
    # Offer the source model to Rails for some of the Rails methods (e.g. link_to).
    #
    # @example
    #   link_to '...', SolrDocument(:id => 'bXXXXXX5').new => <a href="/dams_object/bXXXXXX5">...</a>
    def to_model
      @model ||= ActiveFedoraDummyModel.new(hydra_model, id)
    end

    ##
    # @return [Boolean]
    def collection?
      hydra_model == Hyrax.config.collection_class
    end

    ##
    # @return [Boolean]
    def file_set?
      hydra_model == ::FileSet
    end

    ##
    # @return [Boolean]
    def admin_set?
      hydra_model == Hyrax.config.admin_set_class
    end

    ##
    # @return [Boolean]
    def work?
      Hyrax.config.curation_concerns.include? hydra_model
    end

    # Method to return the model
    def hydra_model(classifier: nil)
      first('has_model_ssim')&.safe_constantize ||
        model_classifier(classifier).classifier(self).best_model
    end

    def depositor(default = '')
      val = first("depositor_tesim")
      val.presence || default
    end

    def creator
      solr_term = hydra_model == AdminSet ? "creator_ssim" : "creator_tesim"
      fetch(solr_term, [])
    end

    def visibility
      @visibility ||= if embargo_release_date.present?
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
                      elsif lease_expiration_date.present?
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
                      elsif public?
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
                      elsif registered?
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
                      else
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
                      end
    end

    def collection_type_gid
      first(Hyrax.config.collection_type_index_field)
    end

    private

    def model_classifier(classifier)
      classifier || ActiveFedora.model_mapper
    end
  end
end
