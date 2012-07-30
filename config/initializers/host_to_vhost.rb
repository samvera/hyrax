require 'socket'
require 'uri'

# Returns an array containing the vhost name and URL
def get_vhost_by_host
  hostname = Socket.gethostname
  vhost = Rails.application.config.hosts_vhosts_map[hostname] || "https://#{hostname}/"
  return [URI.parse(vhost).host, vhost]
end
