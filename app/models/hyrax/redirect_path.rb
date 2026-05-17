# frozen_string_literal: true

module Hyrax
  # ActiveRecord-backed redirects table for global path uniqueness and
  # request-time alias resolution.
  #
  # Each row carries:
  # - `source_path` — the alias path a visitor follows. Unique across all
  #   records (enforced by a DB-level unique index).
  # - `target_path` — where the alias resolves. Equal to the display alias's
  #   path when the record has a display alias set; otherwise the record's
  #   permanent UUID path (e.g. /concern/generic_works/<id>).
  # - `display` — boolean; true on at most one row per record.
  # - `resource_id` — the work or collection this alias belongs to.
  #
  # Maintained by Hyrax::Transactions::Steps::SyncRedirectPaths and
  # Hyrax::Transactions::Steps::RemoveRedirectPaths; queried by
  # Hyrax::RedirectsLookup.
  class RedirectPath < ActiveRecord::Base
    self.table_name = 'hyrax_redirect_paths'
  end
end
