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




0.times do |i|
	title = "Work #{i}"
    custom_id = "wwork_#{i}"
    work = Monograph.new(id: custom_id)
    work.title = title
    work.description = ["A description for Work #{i}"]
    work.visibility = "restricted"
    work.creator = ["user1"]
    work.member_of_collection_ids = ["collection_2"]
    work.rights_statement = ["http://rightsstatements.org/vocab/CNE/2.0/"]
    Hyrax.persister.save(resource: work)


end

5.times do |i|
    i += 100  # TODO: REMOVE
	title = "Collection #{i}"
    custom_id = "collection_#{i}"
    collection = Hyrax::PcdmCollection.new(id: custom_id)
    collection.title = title
    #collection = Collection.new(title:[title])
    collection.description = ["A description for Collection #{i}"]
    collection.visibility="open"
    # TODO: fix collection/work association
    # collection.member_ids = ["wwork_#{i}"]
    collection_type = "gid://dassie/Hyrax::CollectionType/9"
    collection.collection_type_gid = collection_type
    collection.creator = ["user1"]
    pp collection
    Hyrax.persister.save(resource: collection)


end
