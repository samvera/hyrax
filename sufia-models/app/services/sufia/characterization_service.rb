module Sufia
  # Run FITS to gather technical metadata about the content and the full text.
  # Store this extracted metadata in the characterization datastream.
  class CharacterizationService
    include Hydra::Derivatives::ExtractMetadata

    delegate :mime_type, :uri, to: :@generic_file
    attr_reader :generic_file

    def self.run(generic_file)
      new(generic_file).characterize
    end

    def initialize(generic_file)
      @generic_file = generic_file
    end

    ## Extract the metadata from the original_file and record it in the characterization datastream
    def characterize
      store_metadata(extract_metadata)
      store_fulltext(extract_fulltext)
      generic_file.filename = [generic_file.original_file.original_name]
    end

    protected

      def store_fulltext(extracted_text)
        generic_file.full_text.content = extracted_text if extracted_text.present?
      end

      def extract_fulltext
        FullTextExtractionService.run(@generic_file)
      end

      def store_metadata(metadata)
        generic_file.characterization.ng_xml = metadata if metadata.present?
        append_metadata
      end

      def extract_metadata
        return unless generic_file.original_file.has_content?
        Hydra::FileCharacterization.characterize(generic_file.original_file.content, filename_for_characterization.join, :fits) do |config|
          config[:fits] = Hydra::Derivatives.fits_path
        end
      end

      # Populate GenericFile's properties with fields from FITS (e.g. Author from pdfs)
      def append_metadata
        terms = generic_file.characterization_terms
        Sufia.config.fits_to_desc_mapping.each_pair do |k, v|
          if terms.has_key?(k)
            # coerce to array to remove a conditional
            terms[k] = [terms[k]] unless terms[k].is_a? Array
            terms[k].each do |term_value|
              proxy_term = generic_file.send(v)
              if proxy_term.kind_of?(Array)
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
end
