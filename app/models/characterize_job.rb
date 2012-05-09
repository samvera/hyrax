
class CharacterizeJob < Struct.new( :genericFile_id)
  def perform
    generic_file = GenericFile.find(genericFile_id)
    generic_file.characterize
    generic_file.create_thumbnail
  end
    
end
