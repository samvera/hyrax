module Sufia
  module GenericFile
    module Characterization
      extend ActiveSupport::Concern
      included do
        contains "characterization", class_name: 'FitsDatastream'
        has_attributes :mime_type, datastream: :characterization, multiple: false
        has_attributes :format_label, :file_size, :last_modified,
                                        :filename, :original_checksum, :rights_basis,
                                        :copyright_basis, :copyright_note,
                                        :well_formed, :valid, :status_message,
                                        :file_title, :file_author, :page_count,
                                        :file_language, :word_count, :character_count,
                                        :paragraph_count, :line_count, :table_count,
                                        :graphics_count, :byte_order, :compression,
                                        :color_space, :profile_name,
                                        :profile_version, :orientation, :color_map,
                                        :image_producer, :capture_device,
                                        :scanning_software, :exif_version,
                                        :gps_timestamp, :latitude, :longitude,
                                        :character_set, :markup_basis,
                                        :markup_language, :bit_depth,
                                        :channels, :data_format, :offset, :frame_rate, datastream: :characterization, multiple: true

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

      ## Extract the metadata from the content datastream and record it in the characterization datastream
      def characterize
        metadata = content.extract_metadata
        characterization.ng_xml = metadata if metadata.present?
        append_metadata
        self.filename = [content.original_name]
        save
      end

      # Populate GenericFile's properties with fields from FITS (e.g. Author from pdfs)
      def append_metadata
        terms = self.characterization_terms
        Sufia.config.fits_to_desc_mapping.each_pair do |k, v|
          if terms.has_key?(k)
            # coerce to array to remove a conditional
            terms[k] = [terms[k]] unless terms[k].is_a? Array
            terms[k].each do |term_value|
              proxy_term = self.send(v)
              if proxy_term.kind_of?(Array)
                proxy_term << term_value unless proxy_term.include?(term_value)
              else
                # these are single-valued terms which cannot be appended to
                self.send("#{v}=", term_value)
              end
            end
          end
        end
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
