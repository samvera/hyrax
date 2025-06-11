# frozen_string_literal: true

class Hyrax::Characterization::ValkyrieCharacterizationService
  ##
  # @api public
  # @param [Hyrax::FileMetadata] metadata  which has properties to recieve characterization values
  # @param [Valkyrie::StorageAdapter::StreamFile] source to run characterization against
  # @param [Hash] options the options pass to characterization
  # @option options [Hash{Symbol => Symbol}] parser_mapping
  # @option options [Hydra::Works::Characterization::FitsDocument] parser
  # @option options [Symbol] ch12n_tool
  #
  # @return [void]
  def self.run(metadata:, file:, user: ::User.system_user, **options)
    new(metadata: metadata, file: file, **options).characterize
    saved = Hyrax.persister.save(resource: metadata)
    Hyrax.publisher.publish('file.metadata.updated', metadata: saved, user: user)

    Hyrax.publisher.publish('file.characterized',
                            file_set: Hyrax.query_service.find_by(id: saved.file_set_id),
                            file_id: saved.id.to_s,
                            path_hint: saved.file_identifier.to_s)
  end

  ##
  # @!attribute [rw] source
  #   @return [Valkyrie::StorageAdapter::StreamFile]
  # @!attribute [rw] metadata
  #   @return [Hyrax::FileMetadata]
  # @!attribute [rw] parser
  #   @return [Hydra::Works::Characterization::FitsDocument]
  # @!attribute [rw] source
  #   @return [Valkyrie::StorageAdapter::StreamFile]
  # @!attribute [rw] tools
  #   can be :fits, :fits_servlet, :ffprobe or any other service added to HydraFileCharacterization
  #   note that ffprope is faster but only works on AV files.
  #   @return [Symbol]
  attr_accessor :mapping, :metadata, :parser, :source, :tools

  ##
  # @api private
  def initialize( # rubocop:disable Metrics/ParameterLists
    metadata:,
    file:,
    characterizer: Hydra::FileCharacterization,
    parser_mapping: Hydra::Works::Characterization.mapper,
    parser: Hydra::Works::Characterization::FitsDocument.new,
    ch12n_tool: :fits
  )
    @characterizer = characterizer
    @metadata      = metadata
    @source        = file
    @mapping       = parser_mapping
    @parser        = parser
    @tools         = ch12n_tool
  end

  ##
  # @api private
  #
  # Coerce given source into a type that can be passed to Hydra::FileCharacterization
  # Use Hydra::FileCharacterization to extract metadata (an OM XML document)
  # Get the terms (and their values) from the extracted metadata
  # Assign the values of the terms to the properties of the metadata object
  #
  # @return [void]
  def characterize
    terms = parse_metadata(extract_metadata(content))
    apply_metadata(terms)
  end

  protected

  def content
    source.rewind
    source.read
  end

  def extract_metadata(content)
    @characterizer.characterize(content, file_name, tools) do |cfg|
      cfg[:fits] = Hydra::Derivatives.fits_path
    end
  end

  def file_name
    metadata.original_filename
  end

  def parse_metadata(metadata)
    doc = parser
    doc.ng_xml = Nokogiri::XML(metadata) if metadata.present?
    doc.__cleanup__ if doc.respond_to? :__cleanup__
    characterization_terms(doc)
  end

  # Get proxy terms and values from the parser
  def characterization_terms(doc)
    h = {}

    doc.class.terminology.terms.each_pair do |key, _target|
      h[key] = doc.public_send(key)
    rescue NoMethodError
      next
    end

    h.compact
  end

  # Assign values of the instance properties from the metadata mapping :prop => val
  # @todo push exceptional per-property behavior into the mapping somehow?
  # @return [Hash]
  def apply_metadata(terms)
    values_by_property(terms).each do |property, values|
      value = if property == :mime_type
                values.last
              elsif [:height, :width].include?(property)
                # keep only the max height or width
                values.map(&:to_i).max.to_s
              else
                values
              end
      metadata.public_send("#{property}=", value)
    end
  end

  # Check parser_config then self for matching term.
  # Return property symbol or nil
  def property_for(term)
    if mapping.key?(term) && metadata.respond_to?(mapping[term])
      mapping[term]
    elsif metadata.respond_to?(term)
      term
    end
  end

  # Map each term to the corresponding property
  # (multiple terms can map to the same property),
  # and gather all values for each property
  # @return [Hash]
  def values_by_property(terms)
    terms.each_with_object({}) do |(term, value), property_values|
      next unless (property = property_for(term))

      (property_values[property] ||= []).concat(Array(value))
    end
  end
end
