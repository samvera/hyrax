module Hyrax
  class SelectTypePresenter
    def initialize(concern)
      @concern = concern
    end

    attr_reader :concern

    def icon_class
      ModelIcon.css_class_for(concern)
    end

    def description
      translate('description')
    end

    def name
      translate('name')
    end

    def switch_to_new_work_path(route_set:, params:)
      if params.key?(:add_works_to_collection)
        route_set.new_polymorphic_path(concern, add_works_to_collection: params[:add_works_to_collection])
      else
        route_set.new_polymorphic_path(concern)
      end
    end

    def switch_to_batch_upload_path(route_set:, params:)
      if params.key?(:add_works_to_collection)
        route_set.new_batch_upload_path(payload_concern: concern, add_works_to_collection: params[:add_works_to_collection])
      else
        route_set.new_batch_upload_path(payload_concern: concern)
      end
    end

    private

      def object_name
        @object_name ||= concern.model_name.i18n_key
      end

      def translate(key)
        defaults = []
        defaults << :"hyrax.select_type.#{object_name}.#{key}"
        defaults << :"hyrax.select_type.#{key}"
        defaults << ''
        I18n.t(defaults.shift, default: defaults)
      end
  end
end
