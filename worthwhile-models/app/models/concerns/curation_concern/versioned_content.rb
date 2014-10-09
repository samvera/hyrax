module CurationConcern
  module VersionedContent
    def versions
      return [] unless persisted?
      @versions ||= content.versions.collect {|version| Worthwhile::ContentVersion.new(content, version)}
    end

    def latest_version
      versions.first || Worthwhile::ContentVersion::Null.new(content)
    end

    def current_version_id
      latest_version.version_id
    end
  end
end

