class DownloadsController < ApplicationController
  # module mixes in normalize_identifier method
  include Sufia::DownloadsControllerBehavior
end
