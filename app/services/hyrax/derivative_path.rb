# frozen_string_literal: true
module Hyrax
  class DerivativePath
    attr_reader :id, :destination_name

    class << self
      # Path on file system where derivative file is stored
      # @param [ActiveFedora::Base or String] object either the AF object or its id
      # @param [String] destination_name
      def derivative_path_for_reference(object, destination_name)
        new(object, destination_name).derivative_path
      end

      # @param [ActiveFedora::Base or String] object either the AF object or its id
      # @return [Array<String>] Array of paths to derivatives for this object.
      def derivatives_for_reference(object)
        new(object).all_paths
      end
    end

    # @param [ActiveFedora::Base, String] object either the AF object or its id
    # @param [String] destination_name
    def initialize(object, destination_name = nil)
      @id = object.is_a?(String) ? object : object.id.to_s
      @destination_name = destination_name.gsub(/^original_file_/, '') if destination_name
    end

    def derivative_path
      "#{path_prefix}-#{file_name}"
    end

    def all_paths
      Dir.glob(root_path.join("*")).select do |path|
        path.start_with?(path_prefix.to_s)
      end
    end

    def pairs
      @pairs ||= id.split('').each_slice(2).map(&:join)
    end

    def pair_directory
      pairs[0..-2]
    end

    def pair_path
      (pair_directory + pairs[-1..-1]).join('/')
    end

    private

    # @return [String] Returns the root path where derivatives will be generated into.
    def root_path
      Pathname.new(derivative_path).dirname
    end

    # @return <Pathname> Full prefix of the path for object.
    def path_prefix
      Pathname.new(Hyrax.config.derivatives_path).join(pair_path)
    end

    def file_name
      return unless destination_name
      destination_name + extension
    end

    def extension
      case destination_name
      when 'thumbnail'
        ".#{MIME::Types.type_for('jpg').first.extensions.first}"
      when 'extracted_text'
        ".#{MIME::Types.type_for('txt').first.extensions.first}"
      else
        ".#{destination_name}"
      end
    end
  end
end
