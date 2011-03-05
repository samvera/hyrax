class UserSessionsController < ApplicationController
  #
  # PubCookie will only be used to trigger the authentication server once.
  # After the user succesfully logs in, PubCookie will redirect back to the "new" action here.
  # Once we get the REMOTE_USER value from PubCookie (Apache)
  # we set our own session value and never bother with PubCookie again.
  #
  # In production, for the :80 section of the configs, Apache should be set up to do a 
  # redirect for /login and /logout to an SSL request.  Also, for the :443 section of the
  # configs, /login and /logout should be set up to turn on and off NetBadge authentication.
  # If these steps aren't in place, a temp account will be created
  #
  ### Example for the :80 section 
  # RewriteEngine On
  # RewriteLog  "/var/log/httpd/hydrangea_rewrite_log"
  # RewriteLogLevel 2
  # RewriteCond %{HTTPS} !=on
  # RewriteRule ^/login https://%{HTTP_HOST}/login [R=301,L]
  # RewriteRule ^/logout https://%{HTTP_HOST}/logout [R=301,L]
  # RewriteRule ^/user_sessions/new https://%{HTTP_HOST}/login [R=301,L]
  ### Example for the :443 section
  # <Location /login>
  #   AuthType NetBadge
  #   require valid-user
  #   PubcookieAppId hydrangea
  #   PubcookieInactiveExpire -1
  # </Location>
  # <Location /logout>
  #   PubcookieEndSession on
  # </Location>
   
  def new
    # if the session is already set, use the session login
    if session[:login]
      user = User.find_by_login(session[:login])
      # request coming from PubCookie... get login from REMOTE_USER
    elsif request.env['REMOTE_USER']
      user = User.find_or_create_by_login(request.env['REMOTE_USER']) if user.nil?
    else
      # Login the way you normally would in the blacklight plugin
      @user_session = UserSession.new
      @redirect_params = params[:redirect_params]
      return
    end
    # store the user_id in the session
    session[:login] = user.login
    @user_session = UserSession.create(user, true)

    # redirect to the catalog with http protocol
    # make sure there is a session[:search] hash, if not just use an empty hash
    # and merge in the :protocol key

    if @redirect_params
      redirect_to url_for params[:redirect_params]
    else
      redirect_params = (session[:search] || {}).merge(:protocol=>'http')
      redirect_to root_url(redirect_params)
    end
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      if params[:redirect_action] && params[:redirect_controller] && params[:redirect_content_type]
        redirect_to url_for(:action => params[:redirect_action], :controller=>params[:redirect_controller], :content_type => params[:redirect_content_type])
      else
        redirect_to root_path
      end
    else
      flash.now[:error] =  "Couldn't locate a user with those credentials"
      render :action => :new
    end
  end
   
  def destroy
    reset_session
    session[:login] = nil
    current_user_session.destroy if current_user_session
    redirect_params = (session[:search] || {}).merge(:protocol=>'http')
    redirect_to logged_out_url(redirect_params)
  end
    
  def logged_out
  end
  
  # toggle to set superuser_mode in session
  # Only allows user who can be superusers to set this value in session
  def superuser
    if session[:superuser_mode]
      session[:superuser_mode] = nil
    elsif current_user.can_be_superuser?
      session[:superuser_mode] = true
    end
    redirect_to :back
  end

end
