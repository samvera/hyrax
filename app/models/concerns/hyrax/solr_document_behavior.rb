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
    # Given a model class and an +id+, provides +ActiveModel+ style model methods.
    #
    # @note access this via {SolrDocumentBehavior#to_model}.
    class ModelWrapper
      ##
      # @api private
      #
      # @param [Class] model
      # @param [String, nil] id
      def initialize(model, id)
        @model = model
        @id = id
      end

      ##
      # @api public
      def persisted?
        true
      end

      ##
      # @api public
      def to_param
        @id
      end

      ##
      # @api public
      def model_name
        @model.model_name
      end

      ##
      # @api public
      def to_partial_path
        @model._to_partial_path
      end

      ##
      # @api public
      def to_global_id
        URI::GID.build app: GlobalID.app, model_name: model_name.name, model_id: @id
      end
    end
    ##
    # Offer the source model to Rails for some of the Rails methods (e.g. link_to).
    #
    # @example
    #   link_to '...', SolrDocument(:id => 'bXXXXXX5').new => <a href="/dams_object/bXXXXXX5">...</a>
    def to_model
      @model ||= ModelWrapper.new(hydra_model, id)
    end

    ##
    # @return [Boolean]
    def collection?
      hydra_model == ::Collection
    end

    ##
    # @return [Boolean]
    def file_set?
      hydra_model == ::FileSet
    end

    ##
    # @return [Boolean]
    def admin_set?
      hydra_model == ::AdminSet
    end

    # Method to return the model
    def hydra_model(classifier: ActiveFedora.model_mapper)
      "::#{first('has_model_ssim')}".safe_constantize ||
        classifier.classifier(self).best_model
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
      first('collection_type_gid_ssim')
    end
  end
end
