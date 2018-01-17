module Hyrax
  class IIIFAuthorizationService
    attr_reader :controller
    def initialize(controller)
      @controller = controller
    end

    # @note we ignore the `action` param here in favor of the `:show` action for all permissions
    def can?(_action, object)
      controller.current_ability.can?(:show, file_set_for(object))
    end

    private

      def file_set_for(object)
        file_node = Hyrax::Queries.find_by(id: Valkyrie::ID.new(object.id))
        file_set, = Hyrax::Queries.find_parents(resource: file_node)
        file_set
      end
  end
end
