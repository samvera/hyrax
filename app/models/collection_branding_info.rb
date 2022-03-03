# frozen_string_literal: true
class CollectionBrandingInfo < ApplicationRecord
  def initialize(collection_id:,
                 filename:,
                 role:,
                 alt_txt: "",
                 target_url: "")

    super()
    self.collection_id = collection_id
    self.role = role
    self.alt_text = alt_txt
    self.target_url = target_url
    self.local_path = File.join(role, filename)
  end

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

  def delete(location_path = nil)
    id = if location_path
           Deprecation.warn('Passing an explict location path is ' \
                            'deprecated. Call without arguments instead.')
           location_path
         else
           local_path
         end
    storage.delete(id: id)
  end

  def find_local_filename(collection_id, role, filename)
    local_dir = find_local_dir_name(collection_id, role)
    File.join(local_dir, filename)
  end

  def find_local_dir_name(collection_id, role)
    File.join(Hyrax.config.branding_path, collection_id.to_s, role.to_s)
  end

  private

  def storage
    Hyrax.config.branding_storage_adapter
  end
end
