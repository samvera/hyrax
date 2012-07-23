class CharacterizeJob
  @queue = :characterize

  def self.perform(generic_file_id)
    generic_file = GenericFile.find(generic_file_id, :cast => true)
    generic_file.characterize
    generic_file.create_thumbnail
  end
end
