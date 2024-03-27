# frozen_string_literal: true

# Provide plain collection model if not defined by the application.
# Needed until Hyrax internals do not assume its existence.
class ::Collection < Hyrax.config.collection_class; end unless ActiveSupport::Dependencies.then do |deps|
  # In autoloading environments, when referencing +::Collection+ from the
  # initializer, make sure that +safe_constantize+ wouldn’t just try loading
  # this file again (which would produce a runtime error). Do this by manually
  # searching for the file which should define +::Collection+ and checking if it
  # is the one being currently loaded.
  break true if Object.const_defined?(:Collection)
  file_path = deps.search_for_file("collection")
  expanded = File.expand_path(file_path)
  expanded.delete_suffix!(".rb")
  break false if deps.loading.include?(expanded)
  '::Collection'.safe_constantize
end
