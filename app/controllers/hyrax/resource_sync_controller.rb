# frozen_string_literal: true
class Hyrax::ResourceSyncController < ApplicationController
  # We don't need locale here
  def default_url_options
    super.except(:locale)
  end

  def source_description
    render_from_cache_as_xml(:source_description)
  end

  def capability_list
    render_from_cache_as_xml(:capability_list)
  end

  def change_list
    render_from_cache_as_xml(:change_list)
  end

  def resource_list
    render_from_cache_as_xml(:resource_list)
  end

  private

  def build_change_list
    Hyrax::ResourceSync::ChangeListWriter.new(capability_list_url: hyrax.capability_list_url,
                                              resource_host: request.host).write
  end

  def build_resource_list
    Hyrax::ResourceSync::ResourceListWriter.new(capability_list_url: hyrax.capability_list_url,
                                                resource_host: request.host).write
  end

  def build_capability_list
    Hyrax::ResourceSync::CapabilityListWriter.new(resource_list_url: hyrax.resource_list_url,
                                                  change_list_url: hyrax.change_list_url,
                                                  description_url: hyrax.source_description_url).write
  end

  def build_source_description
    Hyrax::ResourceSync::SourceDescriptionWriter.new(capability_list_url: hyrax.capability_list_url).write
  end

  def render_from_cache_as_xml(resource_sync_type)
    # Caching based on host, for multi-tenancy support
    body = Rails.cache.fetch("#{resource_sync_type}_#{request.host}", expires_in: 1.week) do
      send("build_#{resource_sync_type}")
    end
    render body: body, content_type: 'application/xml'
  end
end
