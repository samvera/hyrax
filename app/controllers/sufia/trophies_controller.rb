module Sufia
  class TrophiesController < ApplicationController
    def toggle_trophy
      work_id = params[:id]
      authorize! :edit, work_id
      t = current_user.trophies.where(work_id: work_id).first
      if t
        t.destroy
        return false if t.persisted?
      else
        t = current_user.trophies.create(work_id: work_id)
        return false unless t.persisted?
      end
      render json: t
    end
  end
end
