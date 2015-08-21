module CurationConcerns
  # Run FITS to gather technical metadata about the content and the full text.
  # Store this extracted metadata in the characterization datastream.
  class CharacterizationService
    attr_reader :generic_file

    def self.run(generic_file)
      new(generic_file).characterize
    end

    def initialize(generic_file)
      @generic_file = generic_file
    end

    ## Extract the metadata from the content datastream and record it in the characterization datastream
    def characterize
      store_metadata(extract_metadata)
      store_fulltext(extract_fulltext)
      generic_file.filename = original_file.original_name
    end

    protected

      def store_fulltext(extracted_text)
        return unless extracted_text.present?
        extracted_text_file = generic_file.build_extracted_text
        extracted_text_file.content = extracted_text
      end

      def extract_fulltext
        FullTextExtractionService.run(generic_file)
      end

      def store_metadata(metadata)
        generic_file.characterization.ng_xml = metadata if metadata.present?
        append_metadata
      end

      def original_file
        generic_file.original_file
      end

      def extract_metadata
        return unless original_file.has_content?
        Hydra::FileCharacterization.characterize(original_file.content, original_file.original_name, :fits) do |config|
          config[:fits] = Hydra::Derivatives.fits_path
        end
      end

      # Populate GenericFile's properties with fields from FITS (e.g. Author from pdfs)
      def append_metadata
        terms = generic_file.characterization_terms
        CurationConcerns.config.fits_to_desc_mapping.each_pair do |k, v|
          next unless terms.key?(k)
          # coerce to array to remove a conditional
          terms[k] = [terms[k]] unless terms[k].is_a? Array
          terms[k].each do |term_value|
            proxy_term = generic_file.send(v)
            if proxy_term.is_a?(Array)
              proxy_term << term_value unless proxy_term.include?(term_value)
            else
              # these are single-valued terms which cannot be appended to
              generic_file.send("#{v}=", term_value)
            end
          end
        end
      end
  end
end
