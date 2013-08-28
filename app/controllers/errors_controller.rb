class ErrorsController < ApplicationController
  def routing
    render_404("Route not found: /#{params[:error]}")
  end
end
