# frozen_string_literal: true
module Hyrax
  module Actors
    class EmbargoActor
      attr_reader :work

      # @param [Hydra::Works::Work] work
      def initialize(work)
        @work = work
      end

      # Update the visibility of the work to match the correct state of the embargo, then clear the embargo date, etc.
      # Saves the embargo and the work
      def destroy
        case work
        when Valkyrie::Resource
          Hyrax::EmbargoManager.deactivate_embargo_for(resource: work) &&
            Hyrax.persister.save(resource: work.embargo) &&
            Hyrax::AccessControlList(work).save
        else
          work.embargo_visibility! # If the embargo has lapsed, update the current visibility.
          work.deactivate_embargo!
          work.embargo.save!
          work.save!
        end
      end
    end
  end
end
