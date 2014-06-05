module Worthwhile
  class ControllerResource < CanCan::ControllerResource
    protected

    # Override resource_params to make this a nop. Worthwhile uses actors to assign attributes
    def resource_params
      {}
    end
  end
end
