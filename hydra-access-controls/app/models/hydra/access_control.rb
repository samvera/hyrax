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
      attribute_list.each do |attributes|
        if attributes.key?(:id)
          obj = relationship.find(attributes[:id])
          if has_destroy_flag?(attributes)
            obj.destroy
          else
            obj.update(attributes.except(:id, '_destroy'))
          end
        else
          relationship.create(attributes)
        end
      end
    end

    # def has_destroy_flag?(hash)
    #   ActiveFedora::Type::Boolean.new.cast(hash['_destroy'])
    # end

    def relationship
      @relationship ||= CollectionRelationship.new(self, :contains)
    end

    class CollectionRelationship
      def initialize(owner, reflection)
        @owner = owner
        @relationship = @owner.send(reflection)
      end

      delegate :to_a, :to_ary, :map, :delete, :last, :size, :count, :[],
               :==, :detect, to: :@relationship

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
