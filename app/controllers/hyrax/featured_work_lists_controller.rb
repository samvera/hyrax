# frozen_string_literal: true
module Hyrax
  class FeaturedWorkListsController < ApplicationController
    def create
      authorize! :update, FeaturedWork
      FeaturedWorkList.new.featured_works_attributes = list_params[:featured_works_attributes]
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { head :no_content }
      end
    end

    private

    def list_params
      params.require(:featured_work_list).permit(featured_works_attributes: [:id, :order])
    end
  end
end
