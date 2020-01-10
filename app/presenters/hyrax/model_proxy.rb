module Hyrax
  # Provide the ActiveModel methods so that this object routes the same as the
  # object represented by the solr document.
  module ModelProxy
    delegate :to_param, :to_key, :id, to: :solr_document

    delegate :model_name, to: :_delegated_to

    def to_partial_path
      _delegated_to._to_partial_path
    end

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
        @_delegated_to ||= solr_document.hydra_model
      end
  end
end
