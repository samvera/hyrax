# To enable local file ingest, 
# - Make User model define .directory method that returns a String corresponding to the User's personal import directory on the server. This can be a simple ActiveRecord attribute on the User model, or it can be something more elaborate. 
# - Include this module in your User model, or define a .files() method that behaves the same
# - Set Sufia.config.enable_local_ingest to true
# 
module Sufia::UserLocalDirectoryBehavior
  
  # You can use this validator in your User model.
  # Ensures that a string defining the path to the user's directory has been provided 
  # and corresponds to a real directory on the server.
  # @example
  #   validate :directory_must_exist
  def directory_must_exist
    unless directory.blank? || File.directory?(directory)
      errors.add(:directory, "must be an existing directory")
    end
  end

  # List the contents of the user's directory on the server
  # Indicates whether each item is a directory or not.
  def files
    return [] unless directory.present? && File.directory?(directory)
    Dir[File.join(directory, '*')].inject([]) do |accum, val|
      accum << { name: File.basename(val), directory: File.directory?(val)}
      accum
    end
  end
  
end