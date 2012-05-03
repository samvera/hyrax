class SessionsController < ApplicationController
  def destroy
    cookies.delete(request.env['COSIGN_SERVICE']) if request.env['COSIGN_SERVICE']
    redirect_to ScholarSphere::Application.config.logout_url
  end
end
