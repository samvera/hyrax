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

def set_visibility(resource, visibility)
  writer   = Hyrax::VisibilityWriter.new(resource: resource)
  writer.assign_access_for(visibility: visibility)
  writer.permission_manager.acl.save
end

default_admin_set_id = AdminSet.find_or_create_default_admin_set_id
puts "Default admin set id: #{default_admin_set_id}"
default_admin_user = "admin@example.com"
default_user = "basic_user@example.com"

last_collection_id=nil

5.times do |i|
	title = "Collection #{i}"
    custom_id = "collection_#{i}"
    collection = Hyrax::PcdmCollection.new(id: custom_id)
    last_collection_id=custom_id
    collection.title = title
    collection.description = ["A description for Collection #{i}"]
    collection_type = "gid://dassie/Hyrax::CollectionType/1"
    collection.collection_type_gid = collection_type
    collection.creator = [default_user]

    if i == 2 then
      collection.member_ids=["collection_1"]
    end

    create_resource(default_user, custom_id, collection)

    # This should work, but it doesn't?
    set_visibility( collection, "open" )
end

13.times do |i|
	title = "Work #{i}"
    custom_id = "work_#{i}"
    afWork = GenericWork.new(title: [title], id: custom_id)
    work = afWork.valkyrie_resource
    work.title = title
    work.description = ["A description for Work #{i}"]
    work.visibility = "open"
    work.creator = [default_user]
    work.depositor = [default_user]
    work.admin_set_id = default_admin_set_id
    work.member_of_collection_ids = [last_collection_id] if !last_collection_id.nil?
    work.rights_statement = ["http://rightsstatements.org/vocab/CNE/2.0/"]
    create_resource(default_user, custom_id, work)
    # This should work, but it doesn't?
    set_visibility( work, "open" )

end

