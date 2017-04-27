# Code for [CANCAN] access to Hydra models

module Hydra
  module Ability
    extend ActiveSupport::Concern

    include Blacklight::AccessControls::Ability

    # once you include Hydra::Ability you can add custom permission methods by appending to ability_logic like so:
    #
    # self.ability_logic +=[:setup_my_permissions]

    included do
      include Hydra::PermissionsQuery
      include Blacklight::SearchHelper

      self.ability_logic = [:create_permissions, :edit_permissions, :read_permissions, :discover_permissions, :download_permissions, :custom_permissions]
    end

    def self.user_class
      Hydra.config[:user_model] ?  Hydra.config[:user_model].constantize : ::User
    end

    def initialize(user, options = {})
      @current_user = user || Hydra::Ability.user_class.new # guest user (not logged in)
      @user = @current_user # just in case someone was using this in an override. Just don't.
      @options = options
      @cache = Blacklight::AccessControls::PermissionsCache.new
      hydra_default_permissions()
    end

    def hydra_default_permissions
      grant_permissions
    end

    def create_permissions
      # no op -- this is automatically run as part of self.ability_logic. Override in your own Ability class to set default create permissions.
    end

    def edit_permissions
      # Loading an object from Fedora can be slow, so assume that if a string is passed, it's an object id
      can [:edit, :update, :destroy], String do |id|
        test_edit(id)
      end

      can [:edit, :update, :destroy], ActiveFedora::Base do |obj|
        test_edit(obj.id)
      end

      can [:edit, :update, :destroy], SolrDocument do |obj|
        cache.put(obj.id, obj)
        test_edit(obj.id)
      end
    end

    def read_permissions
      super

      can :read, ActiveFedora::Base do |obj|
        test_read(obj.id)
      end
    end

    def discover_permissions
      super

      can :discover, ActiveFedora::Base do |obj|
        test_discover(obj.id)
      end
    end

    # Download permissions are exercised in Hydra::Controller::DownloadBehavior
    def download_permissions
      can :download, ActiveFedora::File do |file|
        parent_uri = file.uri.to_s.sub(/\/[^\/]*$/, '')
        parent_id = ActiveFedora::Base.uri_to_id(parent_uri)
        can? :read, parent_id # i.e, can download if can read parent resource
      end
    end

    ## Override custom permissions in your own app to add more permissions beyond what is defined by default.
    def custom_permissions
    end

    protected

    def test_edit(id)
      Rails.logger.debug("[CANCAN] Checking edit permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
      group_intersection = user_groups & edit_groups(id)
      result = !group_intersection.empty? || edit_users(id).include?(current_user.user_key)
      Rails.logger.debug("[CANCAN] decision: #{result}")
      result
    end

    def edit_groups(id)
      doc = permissions_doc(id)
      return [] if doc.nil?
      eg = doc[self.class.edit_group_field] || []
      Rails.logger.debug("[CANCAN] edit_groups: #{eg.inspect}")
      return eg
    end

    # edit implies read, so read_groups is the union of edit and read groups
    def read_groups(id)
      rg = super
      rg |= edit_groups(id)
      Rails.logger.debug("[CANCAN] read_groups: #{rg.inspect}")
      rg
    end

    def edit_users(id)
      doc = permissions_doc(id)
      return [] if doc.nil?
      ep = doc[self.class.edit_user_field] ||  []
      Rails.logger.debug("[CANCAN] edit_users: #{ep.inspect}")
      return ep
    end

    # edit implies read, so read_users is the union of edit and read users
    def read_users(id)
      rp = super
      rp |= edit_users(id)
      Rails.logger.debug("[CANCAN] read_users: #{rp.inspect}")
      rp
    end


    module ClassMethods
      def read_group_field
        Hydra.config.permissions.read.group
      end

      def edit_user_field
        Hydra.config.permissions.edit.individual
      end

      def read_user_field
        Hydra.config.permissions.read.individual
      end

      def edit_group_field
        Hydra.config.permissions.edit.group
      end

      def discover_group_field
        Hydra.config.permissions.discover.group
      end

      def discover_user_field
        Hydra.config.permissions.discover.individual
      end
    end
  end
end
