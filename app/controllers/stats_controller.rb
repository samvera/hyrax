class StatsController < ApplicationController
  include Sufia::Breadcrumbs
  include Sufia::SingularSubresourceController

  before_action :build_breadcrumbs, only: [:work, :file]

  def work
    @stats = WorkUsage.new(params[:id])
  end

  def file
    @stats = FileUsage.new(params[:id])
  end
end
