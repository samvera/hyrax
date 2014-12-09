module Sufia
  class VersionPresenter
    attr_reader :version

    def initialize(version)
      @version = version
      @current = false
    end

    delegate :label, :uri, to: :version

    def current!
      @current = true
    end

    def current?
      @current
    end

    def created
      @created ||= version.created.to_time.to_formatted_s(:long_ordinal)
      @created
    end

    def committer
      vc = VersionCommitter.where(version_id: @version.uri)
      return vc.empty? ? nil : vc.first.committer_login
    end
  end
end
