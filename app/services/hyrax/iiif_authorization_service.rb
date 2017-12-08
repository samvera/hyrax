module Hyrax
  class IIIFAuthorizationService
    attr_reader :controller
    def initialize(controller)
      @controller = controller
    end

    def can?(_action, object)
      controller.current_ability.can?(:show, file_set_id_for(object))
    end

    private

      def file_set_id_for(object)
        object.id.split('/').first
      end
  end
end
