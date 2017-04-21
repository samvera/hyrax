module Hyrax
  class CollectionsMigration
    def self.run
      ::Collection.all.each do |collection|
        collection.members.each do |member|
          member.member_of_collections << collection
          unless member.save
            raise "Work #{member.id} failed to save after recording its membership in collection #{collection.id}"
          end
        end
        collection.members = []
        unless collection.save
          raise "Collection #{collection.id} failed to save after emptying its member list"
        end
      end
    end
  end
end
