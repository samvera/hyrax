module CurationConcerns
  module Forms
    class CollectionEditForm
      include HydraEditor::Form
      self.model_class = ::Collection
      self.terms = [:resource_type, :title, :creator, :contributor, :description, :tag, :rights,
                    :publisher, :date_created, :subject, :language, :identifier, :based_near, :related_url]

      # Test to see if the given field is required
      # @param [Symbol] key a field
      # @return [Boolean] is it required or not
      def required?(key)
        model_class.validators_on(key).any? { |v| v.is_a? ActiveModel::Validations::PresenceValidator }
      end
    end
  end
end
