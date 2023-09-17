# frozen_string_literal: true
class CollectionBrandingInfo < ApplicationRecord
  attr_accessor :filename, :alt_txt
  after_initialize :set_collection_attributes

  def save(file_location, upload_file = true)
    filename = File.split(local_path).last
    role_and_filename = File.join(role, filename)

    if upload_file
      storage.upload(resource: Hyrax::PcdmCollection.new(id: collection_id),
                     file: File.open(file_location),
                     original_filename: role_and_filename)
    end

    self.local_path = find_local_filename(collection_id, role, filename)

    FileUtils.remove_file(file_location) if File.exist?(file_location) && upload_file
    super()
  end

  def delete(_location_path = nil)
    storage.delete(id: local_path)
  end

  def find_local_filename(collection_id, role, filename)
    local_dir = find_local_dir_name(collection_id, role)
    File.join(local_dir, filename)
  end

  def find_local_dir_name(collection_id, role)
    File.join(Hyrax.config.branding_path, collection_id.to_s, role.to_s)
  end

  private

  def set_collection_attributes
    self.alt_text ||= alt_txt || ''
    self.local_path ||= File.join(role, filename)
  end

  def storage
    Hyrax.config.branding_storage_adapter
  end
end
