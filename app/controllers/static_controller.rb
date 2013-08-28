class StaticController < ApplicationController
  rescue_from AbstractController::ActionNotFound, :with => :render_404
end
