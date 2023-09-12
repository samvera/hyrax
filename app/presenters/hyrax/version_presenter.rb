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

    def label
      version.try(:label) || version.version_id.to_s
    end

    def created
      @created ||= version.try(:created)&.in_time_zone&.to_formatted_s(:long_ordinal) || "Unknown"
    end

    def committer
      Hyrax::VersionCommitter
        .find_by(version_id: @version.try(:uri) || @version.try(:version_id))
        &.committer_login
    end
  end
end
