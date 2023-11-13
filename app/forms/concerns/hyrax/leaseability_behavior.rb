# frozen_string_literal: true
module Hyrax
  ##
  # A module of form behaviours for embargoes, leases, and resulting
  # visibilities.
  module LeaseabilityBehavior
    def self.included(descendant) # rubocop:disable Metrics/AbcSize
      descendant.property :visibility, default: VisibilityIntention::PRIVATE, populator: :visibility_populator

      descendant.property :embargo, form: Hyrax::Forms::Embargo, populator: :embargo_populator
      descendant.property :lease, form: Hyrax::Forms::Lease, populator: :lease_populator

      # virtual properties for embargo/lease;
      descendant.property :embargo_release_date, virtual: true, prepopulator: proc { |_opts| self.embargo_release_date = model.embargo&.embargo_release_date }
      descendant.property :visibility_after_embargo, virtual: true, prepopulator: proc { |_opts| self.visibility_after_embargo = model.embargo&.visibility_after_embargo }
      descendant.property :visibility_during_embargo, virtual: true, prepopulator: proc { |_opts| self.visibility_during_embargo = model.embargo&.visibility_during_embargo }

      descendant.property :lease_expiration_date, virtual: true,  prepopulator: proc { |_opts| self.lease_expiration_date = model.lease&.lease_expiration_date }
      descendant.property :visibility_after_lease, virtual: true, prepopulator: proc { |_opts| self.visibility_after_lease = model.lease&.visibility_after_lease }
      descendant.property :visibility_during_lease, virtual: true, prepopulator: proc { |_opts| self.visibility_during_lease = model.lease&.visibility_during_lease }
    end

    def embargo_populator(**)
      self.embargo = Hyrax::EmbargoManager.embargo_for(resource: model)
    end

    def lease_populator(**)
      self.lease = Hyrax::LeaseManager.lease_for(resource: model)
    end

    def visibility_populator(fragment:, doc:, **)
      case fragment
      when "embargo"
        self.visibility = doc['visibility_during_embargo']

        doc['embargo'] = doc.slice('visibility_after_embargo',
                                   'visibility_during_embargo',
                                   'embargo_release_date')
      when "lease"
        self.visibility = doc['visibility_during_lease']
        doc['lease'] = doc.slice('visibility_after_lease',
                                   'visibility_during_lease',
                                   'lease_expiration_date')
      else
        self.visibility = fragment
      end
    end
  end
end
