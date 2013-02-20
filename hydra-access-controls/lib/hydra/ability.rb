# Code for [CANCAN] access to Hydra models
require 'cancan'
module Hydra
  module Ability
    extend ActiveSupport::Concern
    
    # once you include Hydra::Ability you can add custom permission methods by appending to ability_logic like so:
    #
    # self.ability_logic +=[:setup_my_permissions]
    
    included do
      include CanCan::Ability
      include Hydra::PermissionsQuery
      include Blacklight::SolrHelper
      class_attribute :ability_logic
      self.ability_logic = [:create_permissions, :edit_permissions, :read_permissions, :custom_permissions]
    end

    def self.user_class
      Hydra.config[:user_model] ?  Hydra.config[:user_model].constantize : ::User
    end

    attr_reader :current_user, :session, :cache

    def initialize(user, session=nil)
      @current_user = user || Hydra::Ability.user_class.new # guest user (not logged in)
      @user = @current_user # just in case someone was using this in an override. Just don't.
      @session = session
      @cache = Hydra::PermissionsCache.new
      hydra_default_permissions()
    end

    ## You can override this method if you are using a different AuthZ (such as LDAP)
    def user_groups
      return @user_groups if @user_groups
      
      @user_groups = default_user_groups
      @user_groups |= current_user.groups if current_user and current_user.respond_to? :groups
      @user_groups |= ['registered'] unless current_user.new_record?
      @user_groups
    end

    def default_user_groups
      # # everyone is automatically a member of the group 'public'
      ['public']
    end
    

    def hydra_default_permissions
      logger.debug("Usergroups are " + user_groups.inspect)
      self.ability_logic.each do |method|
        send(method)
      end
    end

    def create_permissions
      can :create, :all if user_groups.include? 'registered'
    end

    def edit_permissions
      can [:edit, :update, :destroy], String do |pid|
        test_edit(pid)
      end 

      can [:edit, :update, :destroy], ActiveFedora::Base do |obj|
        test_edit(obj.pid)
      end
   
      can :edit, SolrDocument do |obj|
        cache.put(obj.id, obj)
        test_edit(obj.id)
      end       
    end

    def read_permissions
      can :read, String do |pid|
        test_read(pid)
      end

      can :read, ActiveFedora::Base do |obj|
        test_read(obj.pid)
      end 
      
      can :read, SolrDocument do |obj|
        cache.put(obj.id, obj)
        test_read(obj.id)
      end 
    end


    ## Override custom permissions in your own app to add more permissions beyond what is defined by default.
    def custom_permissions
    end
    
    protected

    def test_edit(pid)
      logger.debug("[CANCAN] Checking edit permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
      group_intersection = user_groups & edit_groups(pid)
      result = !group_intersection.empty? || edit_persons(pid).include?(current_user.user_key)
      logger.debug("[CANCAN] decision: #{result}")
      result
    end   
    
    def test_read(pid)
      logger.debug("[CANCAN] Checking read permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
      group_intersection = user_groups & read_groups(pid)
      result = !group_intersection.empty? || read_persons(pid).include?(current_user.user_key)
      result
    end 
    
    def edit_groups(pid)
      doc = permissions_doc(pid)
      return [] if doc.nil?
      eg = doc[self.class.edit_group_field] || []
      logger.debug("[CANCAN] edit_groups: #{eg.inspect}")
      return eg
    end

    # edit implies read, so read_groups is the union of edit and read groups
    def read_groups(pid)
      doc = permissions_doc(pid)
      return [] if doc.nil?
      rg = edit_groups(pid) | (doc[self.class.read_group_field] || [])
      logger.debug("[CANCAN] read_groups: #{rg.inspect}")
      return rg
    end

    def edit_persons(pid)
      doc = permissions_doc(pid)
      return [] if doc.nil?
      ep = doc[self.class.edit_person_field] ||  []
      logger.debug("[CANCAN] edit_persons: #{ep.inspect}")
      return ep
    end

    # edit implies read, so read_persons is the union of edit and read persons
    def read_persons(pid)
      doc = permissions_doc(pid)
      return [] if doc.nil?
      rp = edit_persons(pid) | (doc[self.class.read_person_field] || [])
      logger.debug("[CANCAN] read_persons: #{rp.inspect}")
      return rp
    end

    module ClassMethods
      def read_group_field 
        Hydra.config[:permissions][:read][:group]
      end

      def edit_person_field 
        Hydra.config[:permissions][:edit][:individual]
      end

      def read_person_field 
        Hydra.config[:permissions][:read][:individual]
      end

      def edit_group_field
        Hydra.config[:permissions][:edit][:group]
      end
    end
  end
end
