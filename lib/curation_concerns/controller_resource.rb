module CurationConcerns
  class ControllerResource < CanCan::ControllerResource
    protected

      # Override resource_params to make this a nop. CurationConcerns uses actors to assign attributes
      def resource_params
        {}
      end
  end
end
