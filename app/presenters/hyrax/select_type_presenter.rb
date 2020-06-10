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
      col_id = collection_id(params)
      if col_id
        route_set.new_polymorphic_path(concern, add_works_to_collection: col_id)
      else
        route_set.new_polymorphic_path(concern)
      end
    end

    def switch_to_batch_upload_path(route_set:, params:)
      col_id = collection_id(params)
      if col_id
        route_set.new_batch_upload_path(payload_concern: concern, add_works_to_collection: col_id)
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

    def collection_id(params)
      return nil unless params
      collection_id = params[:add_works_to_collection]
      collection_id ||= params[:id] if params[:id] && params[:controller] == 'hyrax/dashboard/collections'
      collection_id
    end
  end
end
