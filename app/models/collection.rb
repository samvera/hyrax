# frozen_string_literal: true

# Provide plain collection model if not defined by the application.
# Needed until Hyrax internals do not assume its existence.
class ::Collection < Hyrax.config.collection_class; end unless '::Collection'.safe_constantize
