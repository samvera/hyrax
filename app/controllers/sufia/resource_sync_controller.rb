class Sufia::ResourceSyncController < ApplicationController
  def source_description
    # Caching based on host, for multitenancy support
    body = Rails.cache.fetch("source_description_#{request.host}", expires_in: 1.week) do
      build_source_description
    end
    render body: body, content_type: 'application/xml'
  end

  def capability_list
    # Caching based on host, for multitenancy support
    body = Rails.cache.fetch("source_description_#{request.host}", expires_in: 1.week) do
      build_capability_list
    end
    render body: body, content_type: 'application/xml'
  end

  def resource_list
    # Caching based on host, for multitenancy support
    body = Rails.cache.fetch("source_description_#{request.host}", expires_in: 1.week) do
      build_resource_list
    end
    render body: body, content_type: 'application/xml'
  end

  private

    def build_resource_list
      Sufia::ResourceSync::ResourceListWriter.new(capability_list_url: sufia.capability_list_url,
                                                  resource_host: request.host).write
    end

    def build_capability_list
      Sufia::ResourceSync::CapabilityListWriter.new(resource_list_url: sufia.resource_list_url,
                                                    description_url: sufia.source_description_url).write
    end

    def build_source_description
      Sufia::ResourceSync::SourceDescriptionWriter.new(capability_list_url: sufia.capability_list_url).write
    end
end
