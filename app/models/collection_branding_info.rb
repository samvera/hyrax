# frozen_string_literal: true
class CollectionBrandingInfo < ApplicationRecord
  # i = ColectionImageInfo.new()

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

    self.local_path = find_local_filename(collection_id, role, filename)
  end

  def save(file_location, copy_file = true)
    local_dir = find_local_dir_name(collection_id, role)
    FileUtils.mkdir_p local_dir
    FileUtils.cp file_location, local_path unless file_location == local_path || !copy_file
    FileUtils.remove_file(file_location) if File.exist?(file_location) && copy_file
    super()
  end

  def delete(location_path)
    FileUtils.remove_file(location_path) if File.exist?(location_path)
  end

  def find_local_filename(collection_id, role, filename)
    local_dir = find_local_dir_name(collection_id, role)
    File.join(local_dir, filename)
  end

  def find_local_dir_name(collection_id, role)
    File.join(Hyrax.config.branding_path, collection_id.to_s, role.to_s)
  end
end
