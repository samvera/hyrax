module CurationConcerns
  module File
    module Characterization
      extend ActiveSupport::Concern
      included do
        contains "characterization", class_name: 'FitsDatastream'
        property :mime_type,         delegate_to: 'characterization', multiple: false do |index|
          index.as :stored_searchable
        end
        property :format_label,      delegate_to: 'characterization'
        property :file_size,         delegate_to: 'characterization'
        property :last_modified,     delegate_to: 'characterization'
        property :filename,          delegate_to: 'characterization'
        property :original_checksum, delegate_to: 'characterization'
        property :rights_basis,      delegate_to: 'characterization'
        property :copyright_basis,   delegate_to: 'characterization'
        property :copyright_note,    delegate_to: 'characterization'
        property :well_formed,       delegate_to: 'characterization'
        property :valid,             delegate_to: 'characterization'
        property :status_message,    delegate_to: 'characterization'
        property :file_title,        delegate_to: 'characterization'
        property :file_author,       delegate_to: 'characterization'
        property :page_count,        delegate_to: 'characterization'
        property :file_language,     delegate_to: 'characterization'
        property :word_count,        delegate_to: 'characterization'
        property :character_count,   delegate_to: 'characterization'
        property :paragraph_count,   delegate_to: 'characterization'
        property :line_count,        delegate_to: 'characterization'
        property :table_count,       delegate_to: 'characterization'
        property :graphics_count,    delegate_to: 'characterization'
        property :byte_order,        delegate_to: 'characterization'
        property :compression,       delegate_to: 'characterization'
        property :color_space,       delegate_to: 'characterization'
        property :profile_name,      delegate_to: 'characterization'
        property :profile_version,   delegate_to: 'characterization'
        property :orientation,       delegate_to: 'characterization'
        property :color_map,         delegate_to: 'characterization'
        property :image_producer,    delegate_to: 'characterization'
        property :capture_device,    delegate_to: 'characterization'
        property :scanning_software, delegate_to: 'characterization'
        property :exif_version,      delegate_to: 'characterization'
        property :gps_timestamp,     delegate_to: 'characterization'
        property :latitude,          delegate_to: 'characterization'
        property :longitude,         delegate_to: 'characterization'
        property :character_set,     delegate_to: 'characterization'
        property :markup_basis,      delegate_to: 'characterization'
        property :markup_language,   delegate_to: 'characterization'
        property :bit_depth,         delegate_to: 'characterization'
        property :channels,          delegate_to: 'characterization'
        property :data_format,       delegate_to: 'characterization'
        property :offset,            delegate_to: 'characterization'
        property :frame_rate,        delegate_to: 'characterization'

      end

      def width
        characterization.width.blank? ? characterization.video_width : characterization.width
      end

      def height
        characterization.height.blank? ? characterization.video_height : characterization.height
      end

      def duration
        characterization.duration.blank? ? characterization.video_duration : characterization.duration
      end

      def sample_rate
        characterization.sample_rate.blank? ? characterization.video_sample_rate : characterization.sample_rate
      end

      def characterization_terms
        h = {}
        self.characterization.class.terminology.terms.each_pair do |k, v|
          next unless v.respond_to? :proxied_term
          term = v.proxied_term
          begin
            value = self.send(term.name)
            h[term.name] = value unless value.empty?
          rescue NoMethodError
            next
          end
        end
        h
      end

    end
  end
end
