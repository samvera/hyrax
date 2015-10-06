module CurationConcerns
  # Run FITS to gather technical metadata about the content and the full text.
  # Store this extracted metadata in the characterization datastream.
  class CharacterizationService
    attr_reader :file_set, :file_path

    # @param [FileSet] file_set
    # @param [String] file_path path to the file on disk
    def self.run(file_set, file_path)
      new(file_set, file_path).characterize
    end

    # @param [FileSet] file_set
    # @param [String] file_path path to the file on disk
    def initialize(file_set, file_path)
      @file_set = file_set
      @file_path = file_path
    end

    ## Extract the metadata from the content datastream and record it in the characterization datastream
    def characterize
      store_metadata(extract_metadata)
      file_set.filename = File.basename(file_path)
    end

    protected

      def store_metadata(metadata)
        file_set.characterization.ng_xml = metadata if metadata.present?
        append_metadata
      end

      def original_file
        file_set.original_file
      end

      def extract_metadata
        return unless File.exist?(file_path)
        Hydra::FileCharacterization.characterize(File.open(file_path).read, File.basename(file_path), :fits) do |config|
          config[:fits] = Hydra::Derivatives.fits_path
        end
      end

      # Populate FileSet's properties with fields from FITS (e.g. Author from pdfs)
      def append_metadata
        terms = file_set.characterization_terms
        CurationConcerns.config.fits_to_desc_mapping.each_pair do |k, v|
          next unless terms.key?(k)
          # coerce to array to remove a conditional
          terms[k] = [terms[k]] unless terms[k].is_a? Array
          terms[k].each do |term_value|
            proxy_term = file_set.send(v)
            if proxy_term.is_a?(Array)
              proxy_term << term_value unless proxy_term.include?(term_value)
            else
              # these are single-valued terms which cannot be appended to
              file_set.send("#{v}=", term_value)
            end
          end
        end
      end
  end
end
