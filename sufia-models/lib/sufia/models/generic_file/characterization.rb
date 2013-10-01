module Sufia
  module GenericFile
    module Characterization
      extend ActiveSupport::Concern
      included do
        has_metadata :name => "characterization", :type => FitsDatastream
        delegate :mime_type, :to => :characterization, multiple: false
        delegate_to :characterization, [:format_label, :file_size, :last_modified,
                                        :filename, :original_checksum, :rights_basis,
                                        :copyright_basis, :copyright_note,
                                        :well_formed, :valid, :status_message,
                                        :file_title, :file_author, :page_count,
                                        :file_language, :word_count, :character_count,
                                        :paragraph_count, :line_count, :table_count,
                                        :graphics_count, :byte_order, :compression,
                                        :width, :height, :color_space, :profile_name,
                                        :profile_version, :orientation, :color_map,
                                        :image_producer, :capture_device,
                                        :scanning_software, :exif_version,
                                        :gps_timestamp, :latitude, :longitude,
                                        :character_set, :markup_basis,
                                        :markup_language, :duration, :bit_depth,
                                        :sample_rate, :channels, :data_format, :offset], multiple: true

      end

      def characterize_if_changed
        content_changed = self.content.changed?
        yield
        #logger.debug "DOING CHARACTERIZE ON #{self.pid}"
        Sufia.queue.push(CharacterizeJob.new(self.pid)) if content_changed
      end

      ## Extract the metadata from the content datastream and record it in the characterization datastream
      def characterize
        self.characterization.ng_xml = self.content.extract_metadata
        self.append_metadata
        self.filename = self.label
        save
      end

      # Populate descMetadata with fields from FITS (e.g. Author from pdfs)
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
