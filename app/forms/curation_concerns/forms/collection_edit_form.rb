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

      # @return [Hash] All generic files in the collection, file.to_s is the key, file.id is the value
      def select_files
        Hash[all_files]
      end

      class << self
        # Presently we can't put visibility in the terms, because the superclass will try to do
        # Collection.multiple?(:visibility) which raises an UnknownAttributeError error.
        # https://github.com/projecthydra/hydra-editor/issues/99
        def build_permitted_params
          super + [:visibility]
        end
      end

      private

        def all_files
          member_presenters.flat_map(&:file_presenters).map { |x| [x.to_s, x.id] }
        end

        def member_presenters
          PresenterFactory.build_presenters(model.member_ids, WorkShowPresenter, nil)
        end
    end
  end
end
