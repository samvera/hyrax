module Hydra
  class AccessControl < ActiveFedora::Base

    before_destroy do |obj|
      contains.destroy_all
    end

    is_a_container class_name: 'Hydra::AccessControls::Permission'
    accepts_nested_attributes_for :contains, allow_destroy: true

    attr_accessor :owner

    def permissions
      relationship
    end

    def permissions=(records)
      relationship.replace(records)
    end

    def permissions_attributes=(attribute_list)
      raise ArgumentError unless attribute_list.is_a? Array
      any_destroyed = false
      attribute_list.each do |attributes|
        if attributes.key?(:id)
          obj = relationship.find(attributes[:id])
          if has_destroy_flag?(attributes)
            obj.destroy
            any_destroyed = true
          else
            obj.update(attributes.except(:id, '_destroy'))
          end
        else
          relationship.create(attributes)
        end
      end
      # Poison the cache
      relationship.reset if any_destroyed
    end

    def relationship
      @relationship ||= CollectionRelationship.new(self, :contains)
    end

    # This is like a has_many :through relationship
    class CollectionRelationship
      def initialize(owner, reflection)
        @owner = owner
        @relationship = @owner.send(reflection)
      end

      # The graph stored in @owner is now stale, so reload it and clear all caches
      def reset
        @owner.reload
        @relationship.proxy_association.reload
        self
      end

      delegate :to_a, :to_ary, :map, :delete, :first, :last, :size, :count, :[],
               :==, :detect, :empty?, :each, :any?, :all?, :include?, :destroy_all,
               to: :@relationship

      # TODO: if directly_contained relationships supported find, we could just
      # delegate find.
      def find(id)
        return to_a.find { |record| record.id == id } if @relationship.loaded?

        unless id.start_with?(@owner.id)
          raise ArgumentError, "requested ACL (#{id}) is not a member of #{@owner.id}"
        end
        ActiveFedora::Base.find(id)
      end

      # adds one to the target.
      def build(attributes)
        @relationship.build(attributes) do |record|
          record.access_to = @owner.owner
        end
      end

      def create(attributes)
        build(attributes).tap(&:save!)
      end

      def replace(*args)
        @relationship.replace(*args)
      end
    end
  end
end
