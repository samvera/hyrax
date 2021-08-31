# frozen_string_literal: true
module Hyrax
  class UserPinnedCollectionsController < ApplicationController
    def create
      @pin = UserPinnedCollection.create(collection_id: params[:collection_id], user_id: current_user.id)
      respond_to do |format|
        format.json { render json: @pin, status: :created }
        format.html { redirect_to dashboard_path }
      end
    end

    def destroy
      @pin = UserPinnedCollection.where(collection_id: params[:id], user_id: current_user.id).first
      @pin&.destroy
      redirect_to dashboard_path
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to dashboard_path }
      end
    end
  end
end
