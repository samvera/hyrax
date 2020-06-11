# frozen_string_literal: true
module Hyrax
  # Shows the about and help page
  class PagesController < ApplicationController
    load_and_authorize_resource class: ContentBlock, except: :show
    layout :pages_layout

    helper Hyrax::ContentBlockHelper

    def show
      @page = ContentBlock.for(params[:key])
    end

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
      add_breadcrumb t(:'hyrax.admin.sidebar.pages'), hyrax.edit_pages_path
    end

    def update
      respond_to do |format|
        if @page.update(value: update_value_from_params)
          redirect_path = "#{hyrax.edit_pages_path}##{params[:content_block].keys.first}"
          format.html { redirect_to redirect_path, notice: t(:'hyrax.pages.updated') }
        else
          format.html { render :edit }
        end
      end
    end

    private

    def permitted_params
      params.require(:content_block).permit(:about,
                                            :agreement,
                                            :help,
                                            :terms)
    end

    # When a request comes to the controller, it will be for one and
    # only one of the content blocks. Params always looks like:
    #   {'about_page' => 'Here is an awesome about page!'}
    # So reach into permitted params and pull out the first value.
    def update_value_from_params
      permitted_params.values.first
    end

    def pages_layout
      action_name == 'show' ? 'homepage' : 'hyrax/dashboard'
    end
  end
end
