# frozen_string_literal: true

class IiifManifestCachePrewarmJob < Hyrax::ApplicationJob
  ##
  # @param work [ActiveFedora::Base]
  def perform(work)
    presenter = Hyrax::IiifManifestPresenter.new(work)
    manifest_builder.manifest_for(presenter: presenter)
  end

  private

    def manifest_builder
      Hyrax::CachingIiifManifestBuilder.new
    end
end
