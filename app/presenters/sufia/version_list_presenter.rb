module Sufia
  class VersionListPresenter
    def initialize(version_list)
      @raw_list = version_list
    end

    delegate :each, to: :wrapped_list

    private

      def wrapped_list
        @wrapped_list ||= @raw_list.map { |v| Sufia::VersionPresenter.new(v) }.sort { |a,b| b.version.created <=> a.version.created }.tap { |l| l.first.try(:current!) }
      end
  end
end
