module CurationConcerns
  # Run FITS to gather technical metadata about the content and the full text.
  # Store this extracted metadata in the characterization datastream.
  class CharacterizationService
    attr_reader :generic_file, :file_path

    # @param [GenericFile] generic_file
    # @param [String] file_path path to the file on disk
    def self.run(generic_file, file_path)
      new(generic_file, file_path).characterize
    end

    # @param [GenericFile] generic_file
    # @param [String] file_path path to the file on disk
    def initialize(generic_file, file_path)
      @generic_file = generic_file
      @file_path = file_path
    end

    ## Extract the metadata from the content datastream and record it in the characterization datastream
    def characterize
      store_metadata(extract_metadata)
      store_fulltext(extract_fulltext)
      generic_file.filename = File.basename(file_path)
    end

    protected

      def store_fulltext(extracted_text)
        return unless extracted_text.present?
        extracted_text_file = generic_file.build_extracted_text
        extracted_text_file.content = extracted_text
      end

      def extract_fulltext
        Hydra::Works::FullTextExtractionService.run(generic_file, file_path)
      end

      def store_metadata(metadata)
        generic_file.characterization.ng_xml = metadata if metadata.present?
        append_metadata
      end

      def original_file
        generic_file.original_file
      end

      def extract_metadata
        return unless File.exist?(file_path)
        Hydra::FileCharacterization.characterize(File.open(file_path).read, File.basename(file_path), :fits) do |config|
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
