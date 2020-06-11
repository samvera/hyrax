# frozen_string_literal: true
module Hyrax
  class VersionPresenter
    attr_reader :version, :current

    def initialize(version)
      @version = version
      @current = false
    end

    delegate :label, :uri, to: :version
    alias current? current

    def current!
      @current = true
    end

    def created
      @created ||= version.created.in_time_zone.to_formatted_s(:long_ordinal)
    end

    def committer
      vc = Hyrax::VersionCommitter.where(version_id: @version.uri)
      vc.empty? ? nil : vc.first.committer_login
    end
  end
end
