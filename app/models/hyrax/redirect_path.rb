# frozen_string_literal: true

module Hyrax
  # ActiveRecord-backed uniqueness ledger for redirect paths.
  #
  # Maintained by Hyrax::Transactions::Steps::SyncRedirectPaths and
  # Hyrax::Transactions::Steps::RemoveRedirectPaths; queried by
  # Hyrax::RedirectsLookup. The unique index on `path` is the source of truth
  # for "no two records share a redirect path"; this class just exposes it.
  class RedirectPath < ActiveRecord::Base
    self.table_name = 'hyrax_redirect_paths'
  end
end
