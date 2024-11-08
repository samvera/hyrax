# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # Represents a lease for edit through a work. That is, this form can
    # be used to wrap a Work in order to capture state changes related only to
    # its lease, ignoring the work's other fields.
    #
    # @note this supports the edit functionality of
    #   +LeasesControllerBehavior+.
    class WorkLeaseForm < Hyrax::ChangeSet
      property :lease, form: Hyrax::Forms::Lease, populator: :lease_populator, prepopulator: :lease_populator
      property :lease_history, virtual: true, prepopulator: proc { |_opts| self.lease_history = model.lease&.lease_history }
      property :lease_expiration_date, virtual: true, prepopulator: proc { |_opts| self.lease_expiration_date = model.lease&.lease_expiration_date }
      property :visibility_after_lease, virtual: true, prepopulator: proc { |_opts| self.visibility_after_lease = model.lease&.visibility_after_lease }
      property :visibility_during_lease, virtual: true, prepopulator: proc { |_opts| self.visibility_during_lease = model.lease&.visibility_during_lease }

      def lease_populator(**)
        self.lease = Hyrax::LeaseManager.lease_for(resource: model)
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
