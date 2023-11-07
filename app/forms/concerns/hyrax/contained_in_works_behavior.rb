# frozen_string_literal: true
module Hyrax
  ##
  # A module of form behaviours common to PCDM Objects and FileSets.
  module ContainedInWorksBehavior
    ##
    # @api private
    InWorksPrepopulator = proc do |_options|
      self.in_works_ids =
        if persisted?
          Hyrax.query_service
               .find_inverse_references_by(resource: model, property: :member_ids)
               .select(&:work?)
               .map(&:id)
        else
          []
        end
    end

    def self.included(descendant) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      descendant.property :depositor

      descendant.property :visibility, default: VisibilityIntention::PRIVATE, populator: :visibility_populator

      descendant.property :agreement_accepted, virtual: true, default: false, prepopulator: proc { |_opts| self.agreement_accepted = !model.new_record }

      descendant.collection(:permissions,
                 virtual: true,
                 default: [],
                 form: Hyrax::Forms::Permission,
                 populator: :permission_populator,
                 prepopulator: proc { |_opts| self.permissions = Hyrax::AccessControl.for(resource: model).permissions })

      descendant.property :embargo, form: Hyrax::Forms::Embargo, populator: :embargo_populator
      descendant.property :lease, form: Hyrax::Forms::Lease, populator: :lease_populator

      # virtual properties for embargo/lease;
      descendant.property :embargo_release_date, virtual: true, prepopulator: proc { |_opts| self.embargo_release_date = model.embargo&.embargo_release_date }
      descendant.property :visibility_after_embargo, virtual: true, prepopulator: proc { |_opts| self.visibility_after_embargo = model.embargo&.visibility_after_embargo }
      descendant.property :visibility_during_embargo, virtual: true, prepopulator: proc { |_opts| self.visibility_during_embargo = model.embargo&.visibility_during_embargo }

      descendant.property :lease_expiration_date, virtual: true,  prepopulator: proc { |_opts| self.lease_expiration_date = model.lease&.lease_expiration_date }
      descendant.property :visibility_after_lease, virtual: true, prepopulator: proc { |_opts| self.visibility_after_lease = model.lease&.visibility_after_lease }
      descendant.property :visibility_during_lease, virtual: true, prepopulator: proc { |_opts| self.visibility_during_lease = model.lease&.visibility_during_lease }

      descendant.property :in_works_ids, virtual: true, prepopulator: InWorksPrepopulator
    end

    def embargo_populator(**)
      self.embargo = Hyrax::EmbargoManager.embargo_for(resource: model)
    end

    def lease_populator(**)
      self.lease = Hyrax::LeaseManager.lease_for(resource: model)
    end

    # https://trailblazer.to/2.1/docs/reform.html#reform-populators-populator-collections
    def permission_populator(collection:, index:, **)
      Hyrax::Forms::Permission.new(collection[index])
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
