# frozen_string_literal: true

module Hyrax
  class DownloadsController < ApplicationController
    include Hyrax::DownloadBehavior
  end
end
