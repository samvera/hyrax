module CurationConcerns
  #  To use this module, include it in your Actor class
  #  and then add its interpreters wherever you want them to run.
  #  They should be called _before_ apply_attributes is called because
  #  they intercept values in the attributes Hash.
  #
  #  @example
  #  class MyActorClass < BaseActor
  #     include Worthwile::ManagesEmbargoesActor
  #
  #     def create
  #       interpret_visibility && super && copy_visibility
  #     end
  #
  #     def update
  #       interpret_visibility && super && copy_visibility
  #     end
  #  end
  #
  module ManagesEmbargoesActor
    extend ActiveSupport::Concern

    # Interprets embargo & lease visibility if necessary
    # returns false if there are any errors
    def interpret_visibility(attributes=self.attributes)
      should_continue = interpret_embargo_visibility(attributes) && interpret_lease_visibility(attributes)
      if attributes[:visibility]
        curation_concern.visibility = attributes[:visibility]
      end
      return should_continue
    end

    # If user has set visibility to embargo, interprets the relevant information and applies it
    # Returns false if there are any errors and sets an error on the curation_concern
    def interpret_embargo_visibility(attributes=self.attributes)
      if attributes[:visibility] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
        if !attributes[:embargo_release_date]
          curation_concern.errors.add(:visibility, 'When setting visibility to "embargo" you must also specify embargo release date.')
          should_continue = false
        else
          attributes.delete(:visibility)
          curation_concern.apply_embargo(attributes[:embargo_release_date], attributes.delete(:visibility_during_embargo),
                                         attributes.delete(:visibility_after_embargo))
          if curation_concern.embargo
            curation_concern.embargo.save  # See https://github.com/projecthydra/hydra-head/issues/226
          end
          @needs_to_copy_visibility = true
          should_continue = true
        end
      else
        should_continue = true
        # clear embargo_release_date if it isn't being used. Otherwise it sets the embargo_date
        # even though they didn't select embargo on the form.
        attributes.delete(:embargo_release_date)
      end

      attributes.delete(:visibility_during_embargo)
      attributes.delete(:visibility_after_embargo)

      return should_continue
    end

    # If user has set visibility to lease, interprets the relevant information and applies it
    # Returns false if there are any errors and sets an error on the curation_concern
    def interpret_lease_visibility(attributes=self.attributes)
      if attributes[:visibility] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
        if !attributes[:lease_expiration_date]
          curation_concern.errors.add(:visibility, 'When setting visibility to "lease" you must also specify lease expiration date.')
          should_continue = false
        else
          curation_concern.apply_lease(attributes[:lease_expiration_date], attributes.delete(:visibility_during_lease),
                                         attributes.delete(:visibility_after_lease))
          if curation_concern.lease
            curation_concern.lease.save  # See https://github.com/projecthydra/hydra-head/issues/226
          end
          @needs_to_copy_visibility = true
          attributes.delete(:visibility)
          should_continue = true
        end
      else
        # clear lease_expiration_date if it isn't being used. Otherwise it sets the lease_expiration
        # even though they didn't select lease on the form.
        attributes.delete(:lease_expiration_date)
        should_continue = true
      end

      attributes.delete(:visibility_during_lease)
      attributes.delete(:visibility_after_lease)

      return should_continue
    end


    def copy_visibility
      Sufia.queue.push(VisibilityCopyWorker.new(curation_concern.id)) if @needs_to_copy_visibility
      true
    end
  end
end
