
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

    config.resource_types = {
      "Article" => "Article",
      "Audio" => "Audio",
      "Book" => "Book",
      "Capstone Project" => "Capstone Project",
      "Conference Proceeding" => "Conference Proceeding",
      "Dataset" => "Dataset",
      "Dissertation" => "Dissertation",
      "Image" => "Image",
      "Journal" => "Journal",
      "Map or Cartographic Material" => "Map or Cartographic Material",
      "Masters Thesis" => "Masters Thesis",
      "Part of Book" => "Part of Book",
      "Poster" => "Poster",
      "Presentation" => "Presentation",
      "Project" => "Project",
      "Report" => "Report",
      "Research Paper" => "Research Paper",
      "Software or Program Code" => "Software or Program Code",
      "Video" => "Video",
      "Other" => "Other",
    }

    # reflect a field name change (should one happen) in the generic file datastream
    config.metadata_help = {
      "generic_file_resource_type" => "Pre-defined categories to describe the type of file content being uploaded, such as \"article\" or \"dataset.\"  More than one type may be selected.",
      "generic_file_title" => "A name for the file to aid in identifying it. Defaults to the file name, though a more descriptive title is encouraged. <em>This is a required field</em>.",
      "generic_file_tag" => "Words or phrases you select to describe what the file is about. These are used to search for content. <em>This is a required field</em>.",
      "generic_file_subject" => "Headings or index terms describing what the file is about; these <em>do</em> need to conform to an existing vocabulary. Currently ScholarSphere supports Library of Congress Subject Headings.",
      "generic_file_creator" => "The person or group responsible for the file being uploaded. Usually this is the author of the content. Personal names should be entered with the last name first, e.g. \"Smith, John.\" <em>This is a required field</em>.",
      "generic_file_related_url" => "A link to a website or other specific content (audio, video, PDF document) related to the file. An example is the URL of a research project from which the file was derived.",
      "generic_file_based_near" => "A place name related to the file, such as its site of publication, or the city, state, or country the file's contents are about. Calls upon the GeoNames web service (<a href=\"http://www.geonames.org\">http://www.geonames.org</a>).",
      "generic_file_contributor" => "A person or group you want to recognize for playing a role in the creation of the file, but not the primary role. If there is a specific role you would like noted, include it in parentheses, e.g. \"Jones, Mary (advisor).\"",
      "generic_file_date_created" => "The date on which the file was generated. Dates are accepted in the form YYYY-MM-DD, e.g. 1776-07-04.",
      "generic_file_description" => "Free-text notes about the file itself. Examples include abstracts of a paper, citation information for a journal article, or a tag indicating a larger collection to which the file belongs.",
      "generic_file_identifier" => "A unique handle describing the file. An example would be a DOI for a journal article, or an ISBN or OCLC number for a book.",
      "generic_file_language" => " The language of the file content.",
      "generic_file_publisher" => "The person or group making the file available. Generally this is Penn State or the Penn State University Libraries.",
      "generic_file_rights" => "Licensing and distribution information governing access to the file. Select from the provided drop-down list. <em>This is a required field</em>."
    }

    config.permission_levels = {
      "Choose Access"=>"none",
      "View/Download" => "read",
      "Edit" => "edit"
    }

    config.owner_permission_levels = {
      "Edit" => "edit"
    }

end


