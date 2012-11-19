module Sufia
  module HttpHeaderAuth
    extend ActiveSupport::Concern

    included do 
      ## Force the session to be restarted on every request.  The ensures that when the REMOTE_USER header is not set, the user will be logged out.
      prepend_before_filter :clear_session_user
      before_filter :filter_notify
    end

    def self.get_vhost_by_host(config)
      hosts_vhosts_map = config.hosts_vhosts_map
      hostname = Socket.gethostname
      vhost = hosts_vhosts_map[hostname] || "https://#{hostname}/"
      service = URI.parse(vhost).host
      port = URI.parse(vhost).port
      service << "-#{port}" unless port == 443
      return [service, vhost]
    end
    def clear_session_user
      if request.nil?
        logger.warn "Request is Nil, how weird!!!"
        return
      end

      # only logout if the REMOTE_USER is not set in the HTTP headers and a user is set within warden
      # logout clears the entire session including flash messages
      request.env['warden'].logout unless user_logged_in?
    end
    # Override devise method 
    def user_signed_in?
      env['warden'] and env['warden'].user and remote_user_set?
    end

    def remote_user_set?
      # Unicorn seems to translate REMOTE_USER into HTTP_REMOTE_USER
      if Rails.env.development?
        request.env['HTTP_REMOTE_USER'].present?
      else
        request.env['REMOTE_USER'].present?
      end
    end

    def filter_notify
      # remove error inserted since we are not showing a page before going to web access, this error message always shows up a page too late.
      # for the moment just remove it always.  If we show a transition page in the future we may want to  display it then.
      if flash[:alert].present?
        flash[:alert] = [flash[:alert]].flatten.reject do |item|
          # first remove the bogus message
          item == 'You need to sign in or sign up before continuing.'
          # Also, remove extraneous paperclip errors for weird file types
          item =~ /is not recognized by the 'identify' command/
        end
        # then make the flash nil if that was the only message in the flash
        flash[:alert] = nil if flash[:alert].blank?
      end
    end

  end
end
