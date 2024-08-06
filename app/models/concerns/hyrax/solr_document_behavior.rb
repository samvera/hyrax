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
      Hyrax::ModelRegistry.collection_classes.include?(hydra_model)
    end

    ##
    # @return [Boolean]
    def file_set?
      Hyrax::ModelRegistry.file_set_classes.include?(hydra_model)
    end

    ##
    # @return [Boolean]
    def admin_set?
      Hyrax::ModelRegistry.admin_set_classes.include?(hydra_model)
    end

    ##
    # @return [Boolean]
    def work?
      Hyrax::ModelRegistry.work_classes.include?(hydra_model)
    end

    ##
    # @return [Boolean]
    def valkyrie?
      self['valkyrie_bsi']
    end

    # Method to return the model
    def hydra_model(classifier: nil)
      model = first('has_model_ssim')&.safe_constantize
      model = (first('has_model_ssim')&.+ 'Resource')&.safe_constantize if Hyrax.config.valkyrie_transition?
      model || model_classifier(classifier).classifier(self).best_model
    end

    def depositor(default = '')
      val = first("depositor_tesim")
      val.presence || default
    end

    def creator
      # TODO: should we replace "hydra_model == AdminSet" with by #admin_set?
      solr_term = hydra_model == AdminSet ? "creator_ssim" : "creator_tesim"
      fetch(solr_term, [])
    end

    def visibility
      @visibility ||= if embargo_enforced?
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
                      elsif lease_enforced?
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

    def embargo_enforced?
      return false if embargo_release_date.blank?

      indexed_embargo_visibility = first('visibility_during_embargo_ssim')
      # if we didn't index an embargo visibility, assume the release date means
      # it's enforced
      return true if indexed_embargo_visibility.blank?

      # if the visibility and the visibility during embargo are the same, we're
      # enforcing the embargo
      self['visibility_ssi'] == indexed_embargo_visibility
    end

    def lease_enforced?
      return false if lease_expiration_date.blank?

      indexed_lease_visibility = first('visibility_during_lease_ssim')
      # if we didn't index an embargo visibility, assume the release date means
      # it's enforced
      return true if indexed_lease_visibility.blank?

      # if the visibility and the visibility during lease are the same, we're
      # enforcing the lease
      self['visibility_ssi'] == indexed_lease_visibility
    end

    def extensions_and_mime_types
      JSON.parse(self['extensions_and_mime_types_ssm'].first).map(&:with_indifferent_access) if self['extensions_and_mime_types_ssm']
    end

    private

    def model_classifier(classifier)
      classifier || ActiveFedora.model_mapper
    end
  end
end
