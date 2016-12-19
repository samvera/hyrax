module Hyrax
  class FeaturedWorksController < ApplicationController
    def create
      authorize! :create, FeaturedWork
      @featured_work = FeaturedWork.new(work_id: params[:id])

      respond_to do |format|
        if @featured_work.save
          format.json { render json: @featured_work, status: :created }
        else
          format.json { render json: @featured_work.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize! :destroy, FeaturedWork
      @featured_work = FeaturedWork.find_by(work_id: params[:id])
      if @featured_work
        # Handle the case where a separate request may have already
        # destroyed this work
        @featured_work.destroy
      end

      respond_to do |format|
        format.json { head :no_content }
      end
    end
  end
end
