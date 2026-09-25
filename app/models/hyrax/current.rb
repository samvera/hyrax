# frozen_string_literal: true
# Per-request/per-thread scoped state, reset automatically by Rails' executor between requests and jobs.
class Hyrax::Current < ActiveSupport::CurrentAttributes
  attribute :flexible_schema
  attribute :stored_hash_attribute_names
end
