# frozen_string_literal: true
module Hyrax
  # Provide the ActiveModel methods so that this object routes the same as the
  # object represented by the solr document.
  module ModelProxy
    delegate :to_param, :to_key, :id, to: :solr_document
    delegate :model_name, :to_partial_path, to: :_delegated_to

    def persisted?
      true
    end

    def to_model
      self
    end

    ##
    # @deprecated this isn't related to the ModelProxy issue, and has been moved
    #   to `WorkShowPresenter`.
    def valid_child_concerns
      Deprecation.warn "#{self.class}#valid_child_concerns will be removed in Hyrax 4.0."
      Hyrax::ChildTypes.for(parent: solr_document.hydra_model)
    end

    private

    def _delegated_to
      solr_document.to_model
    end
  end
end
