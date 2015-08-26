module CurationConcerns
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

    private

      def _delegated_to
        @_delegated_to ||= solr_document.fetch(Solrizer.solr_name('has_model', :symbol)).first.constantize
      end
  end
end
