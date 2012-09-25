class RedirectToWebAccessFailure < Devise::FailureApp
  def redirect_url
    Rails.application.config.login_url+ (request.env["ORIGINAL_FULLPATH"].blank? ? '' : request.env["ORIGINAL_FULLPATH"])
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
