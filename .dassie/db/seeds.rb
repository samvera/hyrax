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

13.times do |i|
    i += 200 # TODO: remove
    user = "" # TODO: fix user
	title = "Work #{i}"
    custom_id = "wwork_#{i}"
    work = Monograph.new(id: custom_id)
    work.title = title
    work.description = ["A description for Work #{i}"]
    work.visibility = "restricted"
    work.creator = ["user1"]
    work.member_of_collection_ids = ["collection_2"]
    work.rights_statement = ["http://rightsstatements.org/vocab/CNE/2.0/"]
    create_resource(user, custom_id, work)


end

5.times do |i|
    user = "" # TODO: fix user
    i += 200  # TODO: REMOVE
	title = "Collection #{i}"
    custom_id = "collection_#{i}"
    collection = Hyrax::PcdmCollection.new(id: custom_id)
    collection.title = title
    #collection = Collection.new(title:[title])
    collection.description = ["A description for Collection #{i}"]
    collection.visibility="open"
    # TODO: fix collection/work association
    # collection.member_ids = ["wwork_#{i}"]
    collection_type = "gid://dassie/Hyrax::CollectionType/1"
    collection.collection_type_gid = collection_type
    collection.creator = ["user1"]
    pp collection
    create_resource(user, custom_id, collection)
end

