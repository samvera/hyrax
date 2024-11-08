# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # Represents an embargo for edit through a work. That is, this form can
    # be used to wrap a Work in order to capture state changes related only to
    # its embargo, ignoring the work's other fields.
    #
    # @note this supports the edit functionality of
    #   +EmbargoesControllerBehavior+.
    class WorkEmbargoForm < Hyrax::ChangeSet
      property :embargo, form: Hyrax::Forms::Embargo, populator: :embargo_populator, prepopulator: :embargo_populator
      property :embargo_history, virtual: true, prepopulator: proc { |_opts| self.embargo_history = model.embargo&.embargo_history }
      property :embargo_release_date, virtual: true, prepopulator: proc { |_opts| self.embargo_release_date = model.embargo&.embargo_release_date }
      property :visibility_after_embargo, virtual: true, prepopulator: proc { |_opts| self.visibility_after_embargo = model.embargo&.visibility_after_embargo }
      property :visibility_during_embargo, virtual: true, prepopulator: proc { |_opts| self.visibility_during_embargo = model.embargo&.visibility_during_embargo }

      def embargo_populator(**)
        self.embargo = Hyrax::EmbargoManager.embargo_for(resource: model)
      end

      ##
      # @return [String]
      def human_readable_type
        model.to_model.human_readable_type
      end

      ##
      # @return [ActiveModel::Name]
      def model_name
        model.to_model.model_name
      end

      ##
      # @return [String]
      def to_s
        [*model.title].join(' ')
      end
    end
  end
end
