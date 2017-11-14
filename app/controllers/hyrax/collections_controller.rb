module Hyrax
  class CollectionsController < ApplicationController
    include CollectionsControllerBehavior
    include BreadcrumbsForCollections
    layout :decide_layout
    load_and_authorize_resource except: [:index, :show, :create], instance_name: :collection

    self.theme = 'hyrax/1_column'

    # Renders a JSON response with a list of files in this collection
    # This is used by the edit form to populate the thumbnail_id dropdown
    def files
      result = form.select_files.map do |label, id|
        { id: id, text: label }
      end
      render json: result
    end

    private

      def form
        @form ||= change_set_class.new(@collection, current_ability, repository)
      end

      def decide_layout
        case action_name
        when 'show'
          theme
        else
          'dashboard'
        end
      end
  end
end
