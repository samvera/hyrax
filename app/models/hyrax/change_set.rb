# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # Build a changeset class for the given resource class. The ChangeSet will
  # have fields to match the resource class given.
  #
  # To define a custom changeset with validations, use naming convention with "ChangeSet" appended to the end
  # of the resource class name. (e.g. for BookResource, name the change set BookResourceChangeSet)
  #
  # @example
  #   Hyrax::ChangeSet(Monograph)
  def self.ChangeSet(resource_class)
    klass = (resource_class.name + "ChangeSet").safe_constantize || Hyrax::ChangeSet
    Class.new(klass) do
      (resource_class.fields - resource_class.reserved_attributes).each do |field|
        property field, default: nil
      end

      ##
      # @return [String]
      define_singleton_method :inspect do
        return "Hyrax::ChangeSet(#{resource_class})" if name.blank?
        super
      end
    end
  end

  class ChangeSet < Valkyrie::ChangeSet
    ##
    # @api public
    #
    # Factory for resource ChangeSets
    #
    # @example
    #   monograph  = Monograph.new
    #   change_set = Hyrax::ChangeSet.for(monograph)
    #
    #   change_set.title = 'comet in moominland'
    #   change_set.sync
    #   monograph.title # => 'comet in moominland'
    #
    def self.for(resource)
      Hyrax::ChangeSet(resource.class).new(resource)
    end

    ##
    # @api public
    #
    # Forms should be initialized with an explicit +resource:+ parameter to
    # match indexers.
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def initialize(resource = nil)
      if resource.flexible?
        self.class.deserializer_class = nil # need to reload this on first use after schema is loaded
        singleton_class.schema_definitions = self.class.definitions
        context = resource.respond_to?(:context) ? resource.context : nil
        Hyrax::Schema.m3_schema_loader.form_definitions_for(
          schema: resource.class.name,
          version: Hyrax::FlexibleSchema.current_schema_id,
          contexts: context).map do |field_name, options|
            singleton_class.property field_name.to_sym, options.merge(display: options.fetch(:display, true), default: []
          )
        end

        hash = resource.attributes.dup
        hash[:schema_version] = Hyrax::FlexibleSchema.current_schema_id
        resource = resource.class.new(hash)
        # find any fields removed by the new schema
        to_remove = singleton_class.definitions.select { |k, v| !resource.respond_to?(k) && v.instance_variable_get("@options")[:display] }
        to_remove.keys.each do |removed_field|
          singleton_class.definitions.delete(removed_field)
        end
      end

      super(resource)
    end # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
