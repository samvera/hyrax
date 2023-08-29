# frozen_string_literal: true
module Hyrax
  ##
  # @api public
  class VersionListPresenter
    include Enumerable

    attr_reader :versioning_service

    ##
    # @param service [Hyrax::VersioningService]
    def initialize(service)
      @versioning_service = service
    end

    ##
    # @param [Object] an object representing the File Set
    #
    # @return [Hyrax::VersionListPresenter] an enumerable of presenters for the
    #   relevant file versions.
    #
    # @raise [ArgumentError] if we can't build an enu
    def self.for(file_set:)
      original_file = if file_set.respond_to?(:original_file)
                        file_set.original_file
                      else
                        Hyrax::FileSetFileService.new(file_set: file_set).original_file
                      end
      new(Hyrax::VersioningService.new(resource: original_file))
    rescue NoMethodError
      raise ArgumentError
    end

    delegate :each, :empty?, to: :wrapped_list
    delegate :supports_multiple_versions?, to: :versioning_service

    private

    def wrapped_list
      @wrapped_list ||=
        @versioning_service.versions.map { |v| Hyrax::VersionPresenter.new(v) } # wrap each item in a presenter
                 .sort { |a, b| b.version.created <=> a.version.created } # sort list of versions based on creation date
                 .tap { |l| l.first.try(:current!) } # set the first version to the current version
    end
  end
end
