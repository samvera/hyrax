
require 'sufia/http_header_auth'

# TODO move this method to HttpAuth initializer
# Returns an array containing the vhost 'CoSign service' value and URL
Sufia.config do |config|
  config.id_namespace = "sufia"
  config.fits_path = "fits.sh"
  config.fits_to_desc_mapping= {
      :file_title => :title,
      :file_author => :creator
    }

  # TODO move these to an HttpAuth initializer
    # Map hostnames onto vhosts
  config.hosts_vhosts_map = {
    'fedora1test' => 'https://scholarsphere-integration.dlt.psu.edu:8443/',
    'fedora2test' => 'https://scholarsphere-test.dlt.psu.edu/',
    'ss1stage' => 'https://scholarsphere-staging.dlt.psu.edu/',
    'ss2stage' => 'https://scholarsphere-staging.dlt.psu.edu/',
    'ss1prod' => 'https://scholarsphere.psu.edu/',
    'ss2prod' => 'https://scholarsphere.psu.edu/'
  }

  # TODO move these to an HttpAuth initializer
  config.logout_url = "https://webaccess.psu.edu/cgi-bin/logout?#{Sufia::HttpHeaderAuth.get_vhost_by_host(config)[1]}"
  config.login_url = "https://webaccess.psu.edu?cosign-#{Sufia::HttpHeaderAuth.get_vhost_by_host(config)[0]}&#{Sufia::HttpHeaderAuth.get_vhost_by_host(config)[1]}"
end


