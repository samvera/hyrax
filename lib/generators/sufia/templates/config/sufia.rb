
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

  config.max_days_between_audits = 7

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

      config.cc_licenses = {
      'Attribution 3.0 United States' => 'http://creativecommons.org/licenses/by/3.0/us/',
      'Attribution-ShareAlike 3.0 United States' => 'http://creativecommons.org/licenses/by-sa/3.0/us/',
      'Attribution-NonCommercial 3.0 United States' => 'http://creativecommons.org/licenses/by-nc/3.0/us/',
      'Attribution-NoDerivs 3.0 United States' => 'http://creativecommons.org/licenses/by-nd/3.0/us/',
      'Attribution-NonCommercial-NoDerivs 3.0 United States' => 'http://creativecommons.org/licenses/by-nc-nd/3.0/us/',
      'Attribution-NonCommercial-ShareAlike 3.0 United States' => 'http://creativecommons.org/licenses/by-nc-sa/3.0/us/',
      'Public Domain Mark 1.0' => 'http://creativecommons.org/publicdomain/mark/1.0/',
      'CC0 1.0 Universal' => 'http://creativecommons.org/publicdomain/zero/1.0/',
      'All rights reserved' => 'All rights reserved'
    }

    config.cc_licenses_reverse = Hash[*config.cc_licenses.to_a.flatten.reverse]

end


