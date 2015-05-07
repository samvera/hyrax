module CurationConcern
  class PermissionsController < ApplicationController
    include Worthwhile::CurationConcernController
    self.curation_concern_type = ActiveFedora::Base

    def confirm
    end

    def copy
      Sufia.queue.push(CopyPermissionsJob.new(params[:id]))
      redirect_to Sufia::Engine.routes.url_helpers.generic_work_path(params[:id]), notice: I18n.t('sufia.upload.permissions_message')
    end

    def curation_concern
      @curation_concern ||= self.curation_concern_type.find(params[:id], cast: true)
    end
  end
end
