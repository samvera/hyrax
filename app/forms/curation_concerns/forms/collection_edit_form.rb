module CurationConcerns
  module Forms
    class CollectionEditForm
      include HydraEditor::Form
      self.model_class = ::Collection

      delegate :human_readable_type, :member_ids, to: :model

      self.terms = [:resource_type, :title, :creator, :contributor, :description,
                    :tag, :rights, :publisher, :date_created, :subject, :language,
                    :representative_id, :thumbnail_id, :identifier, :based_near,
                    :related_url, :visibility]

      # Test to see if the given field is required
      # @param [Symbol] key a field
      # @return [Boolean] is it required or not
      def required?(key)
        model_class.validators_on(key).any? { |v| v.is_a? ActiveModel::Validations::PresenceValidator }
      end

      # The form only supports a single value for title, so use the first
      # @return [String] the first title
      def title
        model.title.first
      end

      # The form only supports a single value for description, so use the first
      # @return [String] the first description
      def description
        model.description.first
      end

      # @param [Symbol] key the property to test for cardinality
      # @return [FalseClass,TrueClass] whether the value on the form is singular or multipl
      def self.multiple?(key)
        return false if [:title, :description].include? key
        super
      end

      # @param [ActiveSupport::Parameters]
      # @return [Hash] a hash suitable for populating Collection attributes.
      def self.model_attributes(_)
        attrs = super
        # cast title and description back to multivalued
        attrs[:title] = Array(attrs[:title]) if attrs[:title]
        attrs[:description] = Array(attrs[:description]) if attrs[:description]
        attrs
      end

      # @return [Hash] All generic files in the collection, file.to_s is the key, file.id is the value
      def select_files
        Hash[all_files]
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
