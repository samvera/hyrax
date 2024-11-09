# frozen_string_literal: true

# migrates models from AF to valkyrie
class MigrateResourcesJob < ApplicationJob
  attr_accessor :errors
  # input [Array>>String] Array of ActiveFedora model names to migrate to valkyrie objects
  # defaults to AdminSet & Collection models if empty
  def perform(models: ['AdminSet', 'Collection'], ids: [])
    errors = []
    if ids.blank?
      models.each do |model|
        model.constantize.find_each do |item|
          resource = Hyrax.query_service.find_by(id: item.id)
          result = MigrateResourceService.new(resource: resource).call
          errors << result unless result.success?
        end
      end
    else
      ids.each do |id|
        resource = Hyrax.query_service.find_by(id: id)
        next unless resource.wings? # this resource has already been converted
        result = MigrateResourceService.new(resource: resource).call
        errors << result unless result.success?
      end
    end
    raise errors.inspect if errors.present?
  end
end
