# frozen_string_literal: true
module Hyrax
  class TrophiesController < ApplicationController
    before_action :authenticate_user!

    def toggle_trophy
      work_id = params[:id]
      t = current_user.trophies.where(work_id: work_id).first
      if t
        authorize!(:destroy, t)
        t.destroy
      else
        t = current_user.trophies.build(work_id: work_id)
        authorize!(:create, t)
        t.save!
      end
      render json: t
    end
  end
end
