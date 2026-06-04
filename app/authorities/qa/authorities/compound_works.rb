# frozen_string_literal: true

module Qa::Authorities
  ##
  # Autocomplete authority for the compound `work_or_url` sub-field's work
  # picker, mounted at `/authorities/search/compound_works`. Returns readable
  # works matched by {Hyrax::CompoundWorkPickerBuilder}.
  class CompoundWorks < Qa::Authorities::Base
    class_attribute :search_builder_class
    self.search_builder_class = Hyrax::CompoundWorkPickerBuilder

    def search(_q, controller)
      return [] unless controller.current_user

      response, _docs = search_response(controller)
      response.documents.map do |doc|
        { id: doc.id, label: Array(doc.title).first || doc.id, value: doc.id }
      end
    end

    private

    def search_service(controller)
      @search_service ||= Hyrax::SearchService.new(
        config: controller.blacklight_config,
        user_params: controller.params,
        search_builder_class: search_builder_class,
        scope: controller,
        current_ability: controller.current_ability
      )
    end

    def search_response(controller)
      access = controller.params[:access] || 'read'

      search_service(controller).search_results do |builder|
        builder.with({ q: controller.params[:q] })
               .with_access(access)
               .rows(20)
      end
    end
  end
end
