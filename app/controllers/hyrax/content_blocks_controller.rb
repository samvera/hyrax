# frozen_string_literal: true
module Hyrax
  class ContentBlocksController < ApplicationController
    load_and_authorize_resource
    with_themed_layout 'dashboard'

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
      add_breadcrumb t(:'hyrax.admin.sidebar.content_blocks'), hyrax.edit_content_blocks_path
    end

    def update
      respond_to do |format|
        if @content_block.update(value: update_value_from_params)
          format.html { redirect_to hyrax.edit_content_blocks_path, notice: t(:'hyrax.content_blocks.updated') }
        else
          format.html { render :edit }
        end
      end
    end

    private

    def permitted_params
      params.require(:content_block).permit(:marketing,
                                            :announcement,
                                            :researcher)
    end

    # When a request comes to the controller, it will be for one and
    # only one of the content blocks. Params always looks like:
    #   {'about_page' => 'Here is an awesome about page!'}
    # So reach into permitted params and pull out the first value.
    def update_value_from_params
      permitted_params.values.first
    end
  end
end
