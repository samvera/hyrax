class SessionsController < ApplicationController
  def destroy
    cookies.delete('cosign-gamma-ci.dlt.psu.edu')# if ENV['COSIGN_SERVICE']
    redirect_to "https://webaccess.psu.edu/cgi-bin/logout"
  end
end
