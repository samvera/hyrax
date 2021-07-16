# This line loads the Hyrax seed
# Hyrax::Engine.load_seed

# visibility options are
# "open"
# "authenticated"
# "embargo"
# "lease"
# "restricted"
#
# open
# registered
# restricted


def create_resource(user, id, resource)
  begin
    res = Hyrax::metadata_adapter.query_service.find_by(id: id)
  rescue Valkyrie::Persistence::ObjectNotFoundError 
    puts "Resource not found, creating ..."
  end
  return res if res.present?

  Hyrax.persister.save(resource: resource)
  resource
end

default_admin_set_id = "admin_set%2Fdefault"

last_collection_id=nil

5.times do |i|
    user = "" # TODO: fix user
	title = "Collection #{i}"
    custom_id = "collection_#{i}"
    collection = Hyrax::PcdmCollection.new(id: custom_id)
    last_collection_id=custom_id # if last_collection_id.nil?
    collection.title = title
    #collection = Collection.new(title:[title])
    collection.description = ["A description for Collection #{i}"]
    collection.visibility="open"
    # TODO: fix collection/work association
    # collection.member_ids = ["work_#{i}"]
    collection_type = "gid://dassie/Hyrax::CollectionType/1"
    collection.collection_type_gid = collection_type
    collection.creator = ["user1"]
    #pp collection
    create_resource(user, custom_id, collection)
end

puts "LAST COLLECTION ID  #{last_collection_id}"

13.times do |i|
    user = "" # TODO: fix user
	title = "Work #{i}"
    custom_id = "work_#{i}"
    work = Monograph.new(id: custom_id)
    work.title = title
    work.description = ["A description for Work #{i}"]
    work.visibility = "restricted"
    work.creator = ["user1"]
    work.depositor = ["user1"]
    work.admin_set_id = default_admin_set_id
    work.member_of_collection_ids = [last_collection_id] if !last_collection_id.nil?
    work.rights_statement = ["http://rightsstatements.org/vocab/CNE/2.0/"]
    pp work
    create_resource(user, custom_id, work)

end
