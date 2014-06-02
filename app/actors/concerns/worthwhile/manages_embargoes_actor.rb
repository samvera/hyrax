module Worthwhile
  #  To use this module, include it in your Actor class
  #  and then add its interpreters wherever you want them to run.
  #
  #  @example
  #  class MyActorClass < BaseActor
  #     include Worthwile::ManagesEmbargoesActor
  #
  #     def create
  #       interpret_visibility && super
  #     end
  #
  #     def update
  #       interpret_visibility && super
  #     end
  #  end
  #
  module ManagesEmbargoesActor
    extend ActiveSupport::Concern

    # Interprets embargo & lease visibility if necessary
    # returns false if there are any errors
    def interpret_visibility
      interpret_embargo_visibility && interpret_lease_visibility
    end

    # If user has set visibility to embargo, interprets the relevant information and applies it
    # Returns false if there are any errors and sets an error on the curation_concern
    def interpret_embargo_visibility
      if attributes[:visibility] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
        if attributes[:embargo_release_date]
          curation_concern.apply_embargo(attributes[:embargo_release_date],attributes[:visibility_during_embargo], attributes[:visibility_after_embargo])
          attributes[:visibility_during_embargo] =  curation_concern.visibility_during_embargo
          attributes[:visibility_after_embargo] =  curation_concern.visibility_after_embargo
          attributes[:visibility] =  curation_concern.visibility_during_embargo
          return true
        else
          curation_concern.errors.add(:visibility, 'When setting visibility to "embargo" you must also specify embargo release date.')
          return false
        end
      else
        return true
      end
    end

    # If user has set visibility to lease, interprets the relevant information and applies it
    # Returns false if there are any errors and sets an error on the curation_concern
    def interpret_lease_visibility
      if attributes[:visibility] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
        if attributes[:lease_expiration_date]
          curation_concern.apply_lease(attributes[:lease_expiration_date],attributes[:visibility_during_lease], attributes[:visibility_after_lease])
          attributes[:visibility_during_lease] =  curation_concern.visibility_during_lease
          attributes[:visibility_after_lease] =  curation_concern.visibility_after_lease
          attributes[:visibility] =  curation_concern.visibility_during_lease
          return true
        else
          curation_concern.errors.add(:visibility, 'When setting visibility to "lease" you must also specify lease expiration date.')
          return false
        end
      else
        return true
      end
    end
  end
end