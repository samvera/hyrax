module Hyrax
  # Shows the about and help page
  class PagesController < ApplicationController
    load_and_authorize_resource class: ContentBlock, except: :show
    layout :pages_layout

    helper Hyrax::ContentBlockHelper

    def show
      @page = ContentBlock.find_or_create_by(name: params[:id])
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
          format.html { redirect_to hyrax.edit_pages_path, notice: t(:'hyrax.pages.updated') }
        else
          format.html { render :edit }
        end
      end
    end

    protected

      def permitted_params
        params.require(:content_block).permit(:about_page, :help_page)
      end

      # When a request comes to the controller, it will be for one and
      # only one of the content blocks. Params always looks like:
      #   {'about_page' => 'Here is an awesome about page!'}
      # So reach into permitted params and pull out the first value.
      def update_value_from_params
        permitted_params.values.first
      end

    private

      def pages_layout
        action_name == 'show' ? 'homepage' : 'dashboard'
      end
  end
end
