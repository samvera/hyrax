module Sufia
  class GrantEditToDepositorActor < CurationConcerns::Actors::GrantEditToDepositorActor
    private

      # Overriding the parent class so it doesn't grant access
      # if mediated deposit is enabled
      def grant_edit_access
        super unless mediated_deposit?
      end

      def mediated_deposit?
        Flipflop.enable_mediated_deposit?
      end
  end
end
