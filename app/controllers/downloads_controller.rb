class DownloadsController < ApplicationController
  include Hydra::Controller::DownloadBehavior
  prepend_before_filter :normalize_identifier, except: [:index, :new, :create]

  protected

  def normalize_identifier
    params[:id] = Sufia::Noid.namespaceize(params[:id])
  end

end
