# frozen_string_literal: true
module Hyrax
  # An optional model to bring active record like accessors to your Valkyrie resources. This
  # is simply for simplicity in the console and backward compatibility.
  module ArResource
    extend ActiveSupport::Concern

    class_methods do
      ##
      # find a Valkyrie object by its primary identifyer.
      #
      # @param id [String]
      # @return [Valkyrie::Resource]
      def find(id, query_service: Hyrax.query_service)
        query_service.find_by(id: id)
      end

      ##
      # find and item by an arbitrary keyword arguements if and only if that property is supported
      # by the current query_service. custom queries are often limited so be aware that this does
      # support all properties of an object.
      #
      # @params query_service [Valkyrie::QueryService] (optional) the query service to use
      # @param [Hash] opts the options to send to the query service. Can only be one argument.
      #               this argument will be converted to the query in the form of find_by_#{opts.keys.first}
      # @return [Valkyrie::Resource]
      def find_by(query_service: Hyrax.query_service, **opts)
        if opts.key?(:id)
          find(opts[:id], query_service: query_service)
        else
          method_name = "find_by_#{opts.keys.first}"
          value = opts[opts.values.first]
          return query_service.send(method_name, value) if query_service.respond_to?(method_name)
          query_service.custom_query.send(method_name, value)
        end

      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end
    end

    ##
    # @param query_service [#find_parents]
    #
    # @return [NilClass] when this object does not have a parent.
    # @return [Valkyrie::Resource] when this object has at least one parent.
    def parent(query_service: Hyrax.query_service)
      query_service.find_parents(resource: self).first
    end

    ##
    # This will persist the object to the repository. Not a complete transaction set up, but will
    # index and notify listeners of metadata update
    #
    # @param [Hyrax::Persister] Valkyrie persister (optional) will default to Hyrax.persister
    # @param [Hyrax::IndexAdapter] Valkyrie index adapter (optional) will default to Hyrax.index_adapter
    # @param [User] user the user to record the event for. Will not set depositor yet
    # @return [Valkyrie::Resource]
    def save(persister: Hyrax.persister, index_adapter: Hyrax.index_adapter, user: ::User.system_user)
      is_new = new_record
      result = persister.save(resource: self)
      return nil unless result.persisted?
      index_adapter.save(resource: result)
      if result.collection?
        Hyrax.publisher.publish('collection.metadata.updated', collection: result, user: user)
      else
        Hyrax.publisher.publish('object.deposited', object: result, user: user) if is_new
        Hyrax.publisher.publish('object.metadata.updated', object: result, user: user)
      end
      # TODO: do we need to replace the properties here?
      self.new_record = false
      self.id = result.id

      result
    end
    alias create save
    alias update save

    def save!(**opts)
      raise Valkyrie::Persistence::ObjectNotFoundError unless save(**opts)
    end
    alias create! save!
    alias update! save!

    ##
    # This will delete the resource and publish its delete event
    #
    # @param [Hyrax::Persister] Valkyrie persister (optional) will default to Hyrax.persister
    # @param [Hyrax::IndexAdapter] Valkyrie index adapter (optional) will default to Hyrax.index_adapter
    # @param [User] user the user to record the event for. Will not set depositor yet
    # @return [Boolean]
    def destroy(persister: Hyrax.persister, index_adapter: Hyrax.index_adapter, user: ::User.system_user)
      return false unless persisted?
      persister.delete(resource: self)
      index_adapter.delete(resource: self)
      Hyrax.publisher.publish('object.deleted', object: self, user: user)
      true
    end

    def destroy!(**opts)
      raise Valkyrie::Persistence::ObjectNotFoundError unless destroy(**opts)
    end
  end
end
