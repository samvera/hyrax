class DownloadsController < ApplicationController
  include Worthwhile::WithoutNamespace
  include Hydra::Controller::DownloadBehavior
end
