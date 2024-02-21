# frozen_string_literal: true

# Provide plain file set model if not defined by the application.
# Needed until Hyrax internals do not assume its existence.
class ::FileSet < Hyrax.config.file_set_class; end unless '::FileSet'.safe_constantize
