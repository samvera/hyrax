# frozen_string_literal: true
module Hyrax
  ##
  # @api public
  class VersionListPresenter
    include Enumerable

    ##
    # @param version_list [Array<#created>]
    def initialize(version_list)
      @raw_list = version_list
    end

    ##
    # @param [Object] an object representing the File Set
    #
    # @return [Enumerable<Hyrax::VersionPresenter>] an enumerable of presenters
    #   for the relevant file versions.
    #
    # @raise [ArugumentError] if we can't build an enu
    def self.for(file_set:)
      new(file_set.original_file&.versions&.all.to_a)
    rescue NoMethodError
      raise ArgumentError
    end

    delegate :each, to: :wrapped_list

    private

    def wrapped_list
      @wrapped_list ||=
        @raw_list.map { |v| Hyrax::VersionPresenter.new(v) } # wrap each item in a presenter
                 .sort { |a, b| b.version.created <=> a.version.created } # sort list of versions based on creation date
                 .tap { |l| l.first.try(:current!) } # set the first version to the current version
    end
  end
end
