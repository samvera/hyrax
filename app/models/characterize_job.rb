
class CharacterizeJob < Struct.new( :genericFile_id)
  def perform
    generic_file = GenericFile.find(genericFile_id)
    generic_file.characterize
  end
    
end
