module CurationConcerns
  class LocalFileService
    # @param [String] file_name path to the file
    # @param [Hash] _options
    # @yield [File] opens the file and yields it to the block
    def self.call(file_name, _options)
      yield File.open(file_name)
    end
  end
end
