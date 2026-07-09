# frozen_string_literal: true

module Hyrax
  # ActiveRecord-backed redirects table for global path uniqueness.
  #
  # Maintained by Hyrax::Transactions::Steps::SyncRedirectPaths and
  # Hyrax::Transactions::Steps::RemoveRedirectPaths; queried by
  # Hyrax::RedirectsLookup. The unique index on `from_path` is the source
  # of truth for "no two records share a redirect alias"; this class just
  # exposes it.
  class RedirectPath < ActiveRecord::Base
    self.table_name = 'hyrax_redirect_paths'
  end
end
