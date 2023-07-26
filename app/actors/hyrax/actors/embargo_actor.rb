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
          embargo_manager = Hyrax::EmbargoManager.new(resource: work)
          return if embargo_manager.embargo.embargo_release_date.blank?

          embargo_manager.deactivate!
          work.embargo = Hyrax.persister.save(resource: embargo_manager.embargo)
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
