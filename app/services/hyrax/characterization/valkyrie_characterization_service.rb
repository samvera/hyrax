# frozen_string_literal: true
require 'hydra-file_characterization'
require 'nokogiri'

class Hyrax::Characterization::ValkyrieCharacterizationService
  ##
  # @param [Hyrax::FileMetadata] object which has properties to recieve characterization values
  # @param [Valkyrie::StorageAdapter::StreamFile] source to run characterization against
  # @param [Hash] options the options pass to characterization
  # @option options [Hash{Symbol => Symbol}] parser_mapping
  # @option options [Class] parser_class
  # @option options [Object] fits
  # @option options [Object] ch12n_tool
  #
  # @return [Hash]
  def self.run(object, source = nil, options = {})
    new(object, source, options).characterize
    Hyrax.persister.save(resource: object)
  end

  attr_accessor :object, :source, :mapping, :parser_class, :tools

  def initialize(object, source, characterizer: Hydra::FileCharacterization, **options)
    @characterizer = characterizer
    @object        = object
    @source        = source
    @mapping       = options.fetch(:parser_mapping, Hydra::Works::Characterization.mapper)
    @parser_class  = options.fetch(:parser_class, Hydra::Works::Characterization::FitsDocument)
    @tools         = options.fetch(:ch12n_tool, :fits)
  end

  ##
  # Coerce given source into a type that can be passed to Hydra::FileCharacterization
  # Use Hydra::FileCharacterization to extract metadata (an OM XML document)
  # Get the terms (and their values) from the extracted metadata
  # Assign the values of the terms to the properties of the object
  #
  # @return [Hash]
  def characterize
    content = source_to_content
    extracted_md = extract_metadata(content)
    terms = parse_metadata(extracted_md)
    store_metadata(terms)
  end

  protected

  def source_to_content
    source.rewind
    source.read
  end

  def extract_metadata(content)
    @characterizer.characterize(content, file_name, tools) do |cfg|
      cfg[:fits] = Hydra::Derivatives.fits_path
    end
  end

  def file_name
    object.original_filename
  end

  # Use OM to parse metadata
  def parse_metadata(metadata)
    omdoc = parser_class.new
    omdoc.ng_xml = Nokogiri::XML(metadata) if metadata.present?
    omdoc.__cleanup__ if omdoc.respond_to? :__cleanup__
    characterization_terms(omdoc)
  end

  # Get proxy terms and values from the parser
  def characterization_terms(omdoc)
    h = {}
    omdoc.class.terminology.terms.each_pair do |key, target|
      # a key is a proxy if its target responds to proxied_term
      next unless target.respond_to? :proxied_term
      begin
        h[key] = omdoc.send(key)
      rescue NoMethodError
        next
      end
    end
    h.delete_if { |_k, v| v.empty? }
  end

  # Assign values of the instance properties from the metadata mapping :prop => val
  # @return [Hash]
  def store_metadata(terms)
    terms.each_pair do |term, value|
      property = property_for(term)
      next if property.nil?
      # Array-ify the value to avoid a conditional here
      Array(value).each { |v| append_property_value(property, v) }
    end
  end

  # Check parser_config then self for matching term.
  # Return property symbol or nil
  def property_for(term)
    if mapping.key?(term) && object.respond_to?(mapping[term])
      mapping[term]
    elsif object.respond_to?(term)
      term
    end
  end

  def append_property_value(property, value)
    # We don't want multiple mime_types; this overwrites each time to accept last value
    value = Array(object.public_send(property)) + [value] unless property == :mime_type
    # We don't want multiple heights / widths, pick the max
    value = value.map(&:to_i).max.to_s if property == :height || property == :width
    object.send("#{property}=", value)
  end
end
