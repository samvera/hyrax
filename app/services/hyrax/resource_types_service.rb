# frozen_string_literal: true
module Hyrax
  module ResourceTypesService
    extend Hyrax::AuthorityService

    authority_name 'resource_types'
    microdata_namespace 'resource_type.'
  end
end
