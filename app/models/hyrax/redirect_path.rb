# frozen_string_literal: true

module Hyrax
  # ActiveRecord mapping for the `hyrax_redirect_paths` table.
  #
  # See documentation/redirects.md.
  class RedirectPath < ActiveRecord::Base
    self.table_name = 'hyrax_redirect_paths'
  end
end
