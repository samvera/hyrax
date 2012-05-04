class RedirectToWebAccessFailure < Devise::FailureApp
  def redirect_url
    Rails.application.config.login_url
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
