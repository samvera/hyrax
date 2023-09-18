# frozen_string_literal: true

require_dependency 'hyrax/resource_name'

module Hyrax
  ##
  # The base Valkyrie model for Hyrax.
  #
  # @note Hyrax permissions are managed via
  #   [Access Control List](https://en.wikipedia.org/wiki/Access-control_list)
  #   style permissions. Legacy Hyrax models powered by `ActiveFedora` linked
  #   the ACLs from the repository object itself (as an `acl:accessControl` link
  #   to a container). Valkyrie models jettison that approach in favor of relying
  #   on links back from the permissions using `access_to`. As was the case in
  #   the past implementation, we include an object to represent the access list
  #   itself (`Hyrax::AccessControl`). This object's `#access_to` is the way
  #   Hyrax discovers list entries--it MUST match between the `AccessControl`
  #   and its individual `Permissions`.
  #
  #   The effect of this change is that our `AccessControl` objects are detached
  #   from `Hyrax::Resource` they can (and usually should) be edited and
  #   persisted independently from the resource itself.
  #
  #   Some utilitiy methods are provided for ergonomics in transitioning from
  #   `ActiveFedora`: the `#visibility` accessor, and the `#*_users` and
  #   `#*_group` accessors. The main purpose of these is to provide a cached
  #   ACL attached to a given Resource instance. However, these will likely be
  #   deprecated in the future, and it's advisable to avoid them in favor of
  #   `Hyrax::AccessControlList`, `Hyrax::PermissionManager` and/or
  #   `Hyrax::VisibilityWriter` (which provide their underlying
  #   implementations).
  #
  class Resource < Valkyrie::Resource
    include Hyrax::Naming
    include Hyrax::WithEvents

    attribute :alternate_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID)
    attribute :embargo_id,    Valkyrie::Types::ID
    attribute :lease_id,      Valkyrie::Types::ID

    delegate :edit_groups, :edit_groups=,
             :edit_users,  :edit_users=,
             :read_groups, :read_groups=,
             :read_users,  :read_users=, to: :permission_manager

    class << self
      ##
      # @return [String] a human readable name for the model
      def human_readable_type
        I18n.translate("hyrax.models.#{model_name.i18n_key}", default: model_name.human)
      end

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

      private

      ##
      # @api private
      #
      # @return [Class] an ActiveModel::Name compatible class
      def _hyrax_default_name_class
        Hyrax::ResourceName
      end
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
      # TODO do we need to replace the properties here?
      self.new_record = false
      self.id = result.id

      result
    end
    alias_method :create, :save
    alias_method :update, :save

    def save!(**opts)
      raise Valkyrie::Persistence::ObjectNotFoundError unless save(**opts)
    end
    alias_method :create!, :save!
    alias_method :update!, :save!

    ##
    # @return [Boolean]
    def collection?
      false
    end

    ##
    # @return [Boolean]
    def file?
      false
    end

    ##
    # @return [Boolean]
    def file_set?
      false
    end

    ##
    # @return [Boolean]
    def pcdm_object?
      false
    end

    ##
    # @return [Boolean]
    def work?
      false
    end

    def ==(other)
      attributes.except(:created_at, :updated_at) == other.attributes.except(:created_at, :updated_at)
    end

    def permission_manager
      @permission_manager ||= Hyrax::PermissionManager.new(resource: self)
    end

    def visibility=(value)
      visibility_writer.assign_access_for(visibility: value)
    end

    def visibility
      visibility_reader.read
    end

    def embargo=(value)
      raise TypeError "can't convert #{value.class} into Hyrax::Embargo" unless value.is_a? Hyrax::Embargo

      @embargo = value
      self.embargo_id = @embargo.id
    end

    def embargo
      return @embargo if @embargo
      @embargo = Hyrax.query_service.find_by(id: embargo_id) if embargo_id.present?
    end

    def lease=(value)
      raise TypeError "can't convert #{value.class} into Hyrax::Lease" unless value.is_a? Hyrax::Lease

      @lease = value
      self.lease_id = @lease.id
    end

    def lease
      return @lease if @lease
      @lease = Hyrax.query_service.find_by(id: lease_id) if lease_id.present?
    end

    protected

    def visibility_writer
      Hyrax::VisibilityWriter.new(resource: self)
    end

    def visibility_reader
      Hyrax::VisibilityReader.new(resource: self)
    end
  end
end
