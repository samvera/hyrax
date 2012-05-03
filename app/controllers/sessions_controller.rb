class SessionsController < ApplicationController
  def destroy
    cookies.delete(ENV['COSIGN_SERVICE']) if ENV['COSIGN_SERVICE']
    redirect_to "https://weblogin.umich.edu/cgi-bin/logout"
  end
end
