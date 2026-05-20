# frozen_string_literal: true

module Hyrax
  # ActiveRecord-backed redirects table for global path uniqueness and
  # request-time alias resolution.
  #
  # Maintained by Hyrax::Transactions::Steps::SyncRedirectPaths and
  # Hyrax::Transactions::Steps::RemoveRedirectPaths; queried by
  # Hyrax::RedirectsLookup. The unique index on `source_path` is the source
  # of truth for "no two records share a redirect alias." `target_path`
  # stores where the visitor should be sent (NULL means render in place at
  # `source_path`). `display_url` is form/validator state used by the sync
  # step to compute `target_path`; the request-time resolver does not read
  # it.
  class RedirectPath < ActiveRecord::Base
    self.table_name = 'hyrax_redirect_paths'
  end
end
