# frozen_string_literal: true
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
      @featured_work&.destroy

      respond_to do |format|
        format.json { head :no_content }
      end
    end
  end
end
