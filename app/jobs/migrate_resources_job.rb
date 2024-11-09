# frozen_string_literal: true

# migrates models from AF to valkyrie
class MigrateResourcesJob < ApplicationJob
  attr_writer :errors
  # input [Array>>String] Array of ActiveFedora model names to migrate to valkyrie objects
  # defaults to AdminSet & Collection models if empty
  def perform(models: ['AdminSet', 'Collection'], ids: [])
    if ids.blank?
      models.each do |model|
        model.constantize.find_each do |item|
          migrate(item.id)
        end
      end
    else
      ids.each do |id|
        migrate(id)
      end
    end
    raise errors.inspect if errors.present?
  end

  def errors
    @errors ||= []
  end

  def migrate(id)
    resource = Hyrax.query_service.find_by(id: id)
    next unless resource.wings? # this resource has already been converted
    result = MigrateResourceService.new(resource: resource).call
    errors << result unless result.success?
    result
  end
end
