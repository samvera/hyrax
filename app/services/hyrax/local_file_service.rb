# frozen_string_literal: true
module Hyrax
  class LocalFileService
    # @param [String] file_name path to the file
    # @param [Hash] _options
    # @yield [File] opens the file and yields it to the block
    def self.call(file_name, _options)
      File.open(file_name) do |file|
        yield(file)
      end
    end
  end
end
