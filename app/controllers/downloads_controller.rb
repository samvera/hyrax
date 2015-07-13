class DownloadsController < ApplicationController
  include Sufia::DownloadsControllerBehavior

  def self.default_file_path
    'original_file'
  end

end
