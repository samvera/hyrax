class StatsController < ApplicationController
  include Sufia::Breadcrumbs
  include Sufia::SingularSubresourceController

  before_action :build_breadcrumbs, only: [:work, :file]

  def work
  end

  def file
    @stats = FileUsage.new(params[:id])
  end
end
