# frozen_string_literal: true

module Hyrax
  ##
  # This mixin is for {Valkyrie::Resource} objects to be able to read/write the same Solr document
  # as their corresponding {ActiveFedora::Base} object.
  #
  # @see https://github.com/samvera/hyrax/pull/6221 Discussion about having one indexed document
  module ValkyrieLazyMigration
    ##
    # Copy over even more of the {Wings::ModelRegistery} legacy model's model_name properties
    #
    # @note When we remove {Wings}, the downstream implementers will need to explicitly craft the
    #       properties of the model_name.
    class ResourceName < ResourceName
      def initialize(klass, *args)
        super

        legacy_model = Wings::ModelRegistry.lookup(klass)
        return unless legacy_model

        instance_variables.each do |ivar|
          next if ivar == :@name
          next if ivar == :@klass
          next if ivar == :@uncountable
          instance_variable_set(ivar, legacy_model.model_name.send(ivar[1..-1]))
        end
      end
      attr_reader :klass
    end

    ##
    # This function helps configuration a work for a valkyrie migration; namely by helping re-use
    # an existing SOLR document, by specifying that the given :klass is a migration :from another
    # class.
    #
    # @note This is similar to the {Wings::ModelRegistry.register}, but is envisioned as part of
    # the Frigg and Freyja adapters for Postges and Fedora lazy migrations.
    #
    # @param klass [Hyrax::Resource, .attribute]
    # @param from [ActiveFedora::Base, .to_rdf_representation]
    # @param name_class [Hyrax::Name] responsible, in part, for determining the various routing
    #        paths you might use.
    #
    # @example
    #   class MyWork < ActiveFedora::Base
    #   end
    #
    #   class MyWorkResource < Hyrax::Resource
    #     Hyrax::ValkyrieLazyMigration.migrating(self, from: MyWork)
    #   end
    def self.migrating(klass, from:, name_class: Hyrax::ValkyrieLazyMigration::ResourceName)
      Wings::ModelRegistry.register(klass, from)
      from.singleton_class.define_method(:migrating_from) { from }
      from.singleton_class.define_method(:migrating_to) { klass }
      klass.singleton_class.define_method(:migrating_from) { from }
      klass.singleton_class.define_method(:migrating_to) { klass }
      klass.singleton_class.define_method(:_hyrax_default_name_class) { name_class }
      klass.singleton_class.define_method(:to_rdf_representation) { migrating_from.to_rdf_representation }

      klass.include(self)
    end

    extend ActiveSupport::Concern

    included do
      attribute :internal_resource, Valkyrie::Types::Any.default(to_rdf_representation.freeze), internal: true
    end

    def members
      return @members if @members.present?
      @members = member_ids.map do |id|
        Hyrax.query_service.find_by(id: id)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        Rails.logger.warn("Could not find member #{id} for #{self.id}")
      end
    end

    def to_solr
      Hyrax::ValkyrieIndexer.for(resource: self).to_solr
    end
  end
end
