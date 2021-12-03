# frozen_string_literal: true
module Hyrax
  class CollectionsController < ApplicationController
    include CollectionsControllerBehavior
    include BreadcrumbsForCollections
    with_themed_layout :decide_layout
    load_and_authorize_resource except: [:index],
                                instance_name: :collection,
                                class: Hyrax.config.collection_model

    skip_load_resource only: :create if
      Hyrax.config.collection_class < ActiveFedora::Base

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
      @form ||= form_class.new(@collection, current_ability, repository)
    end

    def decide_layout
      layout = case action_name
               when 'show'
                 '1_column'
               else
                 'dashboard'
               end
      File.join(theme, layout)
    end
  end
end
