class DownloadsController < ApplicationController
  include Sufia::Noid # for normalize_identifier method
  include Hydra::Controller::DownloadBehavior
  prepend_before_filter :normalize_identifier, except: [:index, :new, :create]
end
