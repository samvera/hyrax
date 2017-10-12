# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# To use this file, run the following command in the .internal_test_app:
#   rails generate hyrax:sample_data

puts "Creating users"
User.create(email: 'mgr1@example.com', password: 'pppppp') # 6*p
User.create(email: 'mgr2@example.com', password: 'pppppp')
User.create(email: 'dep1@example.com', password: 'pppppp')
User.create(email: 'dep2@example.com', password: 'pppppp')
User.create(email: 'vw1@example.com', password: 'pppppp')
User.create(email: 'vw2@example.com', password: 'pppppp')
user = User.create(email: 'foo@example.com', password: 'foobarbaz')

puts "Creating 'Nestable Collection' type"
options = {
  description: 'Sample collection type that allows nesting of collections.',
  nestable: true, discoverable: true, sharable: true, allow_multiple_membership: true,
  require_membership: false, assigns_workflow: false, assigns_visibility: false,
  participants: [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.admin_group_name, access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                 { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.registered_group_name, access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }]
}
begin
  coltype = Hyrax::CollectionTypes::CreateService.create_collection_type(machine_id: "nestable_collection", title: "Nestable Collection", options: options)
rescue
  puts "  failed to create... looking for existing"
  coltype = Hyrax::CollectionType.find_by_machine_id!("nestable_collection")
end
nestable_gid = coltype.gid

puts "Creating 'Non-Nestable Collection' type"
options = {
  description: 'Sample collection type that DOES NOT allow nesting of collections.',
  nestable: false, discoverable: true, sharable: true, allow_multiple_membership: true,
  require_membership: false, assigns_workflow: false, assigns_visibility: false,
  participants: [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.admin_group_name, access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                 { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.registered_group_name, access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }]
}
begin
  coltype = Hyrax::CollectionTypes::CreateService.create_collection_type(machine_id: "nonnestable_collection", title: "Non-Nestable Collection", options: options)
rescue
  puts "  failed to create... looking for existing"
  coltype = Hyrax::CollectionType.find_by_machine_id!("nonnestable_collection")
end
_nonnestable_gid = coltype.gid

puts "Creating collections for nesting"
# Public User Collection
pnc = Collection.create!(title: ["Public Nestable Collection"], read_groups: ['public'], collection_type_gid: nestable_gid) do |col|
  col.apply_depositor_metadata(user)
end

# Parent Collection
pc = Collection.create!(title: ["A Parent Collection"], read_groups: ['public'], collection_type_gid: nestable_gid) do |parent|
  parent.apply_depositor_metadata(user)
end

# Child Collection
cc = Collection.create!(title: ["A Child Collection"], read_groups: ['public'], collection_type_gid: nestable_gid) do |child|
  child.apply_depositor_metadata(user)
  child.member_of_collections = [pc]
end

puts "Creating works"
# Public
3.times do |i|
  GenericWork.create(title: ["Public #{i}"], read_groups: ['public']) do |work|
    work.apply_depositor_metadata(user)
    work.member_of_collections = [pnc]
  end
end

# Authenticated
2.times do |i|
  GenericWork.create(title: ["Authenticated #{i}"], read_groups: ['registered']) do |work|
    work.apply_depositor_metadata(user)
    work.member_of_collections = [pc]
  end
end

# Private
1.times do |i|
  GenericWork.create(title: ["Private #{i}"]) do |work|
    work.apply_depositor_metadata(user)
    work.member_of_collections = [cc]
  end
end

# Active, Private Embargo
3.times do |i|
  GenericWork.create(title: ["Active Private #{i}"]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_embargo(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
  end
end

# Active, Authenticated Embargo
2.times do |i|
  GenericWork.create(title: ["Active Authenticated #{i}"]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_embargo(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
  end
end

# Expired, Authenticated Embargo
1.times do |i|
  GenericWork.create(title: ["Expired Authenticated #{i}"], read_groups: ['registered']) do |work|
    work.apply_depositor_metadata(user)
    work.apply_embargo(Date.yesterday.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
  end
end

# Expired, Public Embargo
3.times do |i|
  GenericWork.create(title: ["Expired Public #{i}"], read_groups: ['public']) do |work|
    work.apply_depositor_metadata(user)
    work.apply_embargo(Date.yesterday.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
  end
end

# Active, Public Lease
3.times do |i|
  GenericWork.create(title: ["Active Public #{i}"], read_groups: ['public']) do |work|
    work.apply_depositor_metadata(user)
    work.apply_lease(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
  end
end

# Active, Authenticated Lease
2.times do |i|
  GenericWork.create(title: ["Active Authenticated #{i}"], read_groups: ['registered']) do |work|
    work.apply_depositor_metadata(user)
    work.apply_lease(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
  end
end

# Expired, Authenticated Lease
1.times do |i|
  GenericWork.create(title: ["Expired Authenticated #{i}"], read_groups: ['registered']) do |work|
    work.apply_depositor_metadata(user)
    work.apply_lease(Date.yesterday.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
  end
end

# Expired, Private Lease
3.times do |i|
  GenericWork.create(title: ["Expired Public #{i}"]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_lease(Date.yesterday.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
  end
end
