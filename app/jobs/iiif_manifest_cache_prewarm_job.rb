# frozen_string_literal: true

class IiifManifestCachePrewarmJob < Hyrax::ApplicationJob
  ##
  # @param work [ActiveFedora::Base]
  def perform(work)
    manifest_builder.manifest_for(presenter: Hyrax::WorkShowPresenter.new(work))
  end

  private

    def manifest_builder
      Hyrax::CachingIiifManifestBuilder.new
    end
end
