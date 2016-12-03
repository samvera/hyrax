module Hyrax
  class VersionListPresenter
    def initialize(version_list)
      @raw_list = version_list
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
