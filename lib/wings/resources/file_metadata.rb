# frozen_string_literal: true
class FileMetadata < Valkyrie::Resource

  # include Valkyrie::Resource::AccessControls

  # TODO: Everything is a set.  Should it be?  Figgy had everything as sets.
  # TODO: Content in AF can hold a string as content or point to a binary.  Not sure this is adequate.
  # TODO: Should attributes be defined from anywhere other than metadata_node.attributes and the AF file
  # TODO: Although the metadata_node has a mime_type attribute, it is always empty.  The mime_type comes from the AF file.

  attribute :file_identifiers, Valkyrie::Types::Set
  attribute :original_filename, Valkyrie::Types::Set
  attribute :use, Valkyrie::Types::Set

  # TODO: Not sure content should be a set. Sometimes content is a String, sometimes binary file.  Not clear if
  #       both use this content field.
  # attribute :content, Valkyrie::Types::String
  # attribute :binary_content, Valkyrie::Types::String

  # For ActiveFedora, these attributes can be accessed from the FileSet using...
  #   `fileset1.files.first.metadata_node.attributes`
  attribute :mime_type, Valkyrie::Types::Set
  attribute :label, Valkyrie::Types::Set
  attribute :file_name, Valkyrie::Types::Set
  attribute :file_size, Valkyrie::Types::Set
  attribute :date_created, Valkyrie::Types::Set
  attribute :date_modified, Valkyrie::Types::Set
  attribute :byte_order, Valkyrie::Types::Set
  attribute :file_hash, Valkyrie::Types::Set
  attribute :bit_depth, Valkyrie::Types::Set
  attribute :channels, Valkyrie::Types::Set
  attribute :data_format, Valkyrie::Types::Set
  attribute :frame_rate, Valkyrie::Types::Set
  attribute :bit_rate, Valkyrie::Types::Set
  attribute :duration, Valkyrie::Types::Set
  attribute :sample_rate, Valkyrie::Types::Set
  attribute :offset, Valkyrie::Types::Set
  attribute :format_label, Valkyrie::Types::Set
  attribute :well_formed, Valkyrie::Types::Set
  attribute :valid, Valkyrie::Types::Set
  attribute :fits_version, Valkyrie::Types::Set
  attribute :exif_version, Valkyrie::Types::Set
  attribute :original_checksum, Valkyrie::Types::Set
  attribute :file_title, Valkyrie::Types::Set
  attribute :creator, Valkyrie::Types::Set
  attribute :page_count, Valkyrie::Types::Set
  attribute :language, Valkyrie::Types::Set
  attribute :word_count, Valkyrie::Types::Set
  attribute :character_count, Valkyrie::Types::Set
  attribute :line_count, Valkyrie::Types::Set
  attribute :character_set, Valkyrie::Types::Set
  attribute :markup_basis, Valkyrie::Types::Set
  attribute :markup_language, Valkyrie::Types::Set
  attribute :paragraph_count, Valkyrie::Types::Set
  attribute :table_count, Valkyrie::Types::Set
  attribute :graphics_count, Valkyrie::Types::Set
  attribute :compression, Valkyrie::Types::Set
  attribute :height, Valkyrie::Types::Set
  attribute :width, Valkyrie::Types::Set
  attribute :color_space, Valkyrie::Types::Set
  attribute :profile_name, Valkyrie::Types::Set
  attribute :profile_version, Valkyrie::Types::Set
  attribute :orientation, Valkyrie::Types::Set
  attribute :color_map, Valkyrie::Types::Set
  attribute :image_producer, Valkyrie::Types::Set
  attribute :capture_device, Valkyrie::Types::Set
  attribute :scanning_software, Valkyrie::Types::Set
  attribute :gps_timestamp, Valkyrie::Types::Set
  attribute :latitude, Valkyrie::Types::Set
  attribute :longitude, Valkyrie::Types::Set
  attribute :aspect_ratio, Valkyrie::Types::Set

  # TODO: Methods copied from Figgy which may be useful as the conversion to Valkyrie proceeds
  # def self.for(file:)
  #   new(label: file.original_filename,
  #       original_filename: file.original_filename,
  #       mime_type: file.content_type,
  #       use: file.try(:use) || [Valkyrie::Vocab::PCDMUse.OriginalFile],
  #       created_at: Time.current,
  #       updated_at: Time.current)
  # end
  #
  # def derivative?
  #   use.include?(Valkyrie::Vocab::PCDMUse.ServiceFile)
  # end
  #
  # # ServiceFilePartial isn't part of the PCDMUse vocabulary - this is made up
  # def derivative_partial?
  #   use.include?(Valkyrie::Vocab::PCDMUse.ServiceFilePartial)
  # end
  #
  # def original_file?
  #   use.include?(Valkyrie::Vocab::PCDMUse.OriginalFile)
  # end
  #
  # def thumbnail_file?
  #   use.include?(Valkyrie::Vocab::PCDMUse.ThumbnailImage)
  # end
  #
  # def preservation_file?
  #   use.include?(Valkyrie::Vocab::PCDMUse.PreservationMasterFile)
  # end
  #
  # def intermediate_file?
  #   use.include?(Valkyrie::Vocab::PCDMUse.IntermediateFile)
  # end
  #
  # # Populates FileMetadata with fixity check results
  # # @return [FileMetadata] you'll need to save this node after running the fixity
  # def run_fixity
  #   # don't run if there has been a failure.
  #   # probably best to create a new FileSet at that point.
  #   # also don't run if there's no existing checksum; characterization hasn't finished
  #   return self if fixity_success&.zero? || checksum.empty?
  #   actual_file = Valkyrie.config.storage_adapter.find_by(id: file_identifiers.first)
  #   new_checksum = MultiChecksum.for(actual_file)
  #   if checksum.include? new_checksum
  #     self.fixity_success = 1
  #     self.fixity_actual_checksum = [new_checksum]
  #     self.fixity_last_success_date = Time.now.utc
  #   else
  #     self.fixity_success = 0
  #     self.fixity_actual_checksum = [new_checksum]
  #   end
  #   self
  # end
end
