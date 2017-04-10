module Hyrax
  class CollectionsMigration
    def self.run
      ::Collection.all.each do |collection|
        collection.members.each do |member|
          member.member_of_collections << collection
          member.save
        end
        collection.members = []
        collection.save
      end
    end
  end
end
