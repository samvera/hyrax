# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#
# To use this file, run the following command in the .internal_test_app:
#   rails generate hyrax:sample_data
#
# To re-use this file, you will likely want to clean out the test app content
#   rails console
#     require 'active_fedora/cleaner'
#     ActiveFedora::Cleaner.clean!
#     exit
#   rake db:drop db:create db:migrate
#   bin/rails hyrax:default_admin_set:create
#   rake db:seed

# ---------------------------------
# methods to create various objects
# ---------------------------------
def create_collection_type(machine_id, options)
  coltype = Hyrax::CollectionType.find_by_machine_id(machine_id)
  return coltype if coltype.present?
  default_options = {
    nestable: false, discoverable: false, sharable: false, allow_multiple_membership: false,
    require_membership: false, assigns_workflow: false, assigns_visibility: false,
    participants: [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.admin_group_name, access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                   { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.registered_group_name, access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }]
  }
  final_options = default_options.merge(options.except(:title))
  Hyrax::CollectionTypes::CreateService.create_collection_type(machine_id: machine_id, title: options[:title], options: final_options)
end

def create_public_collection(user, type_gid, id, options)
  options[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  create_collection(user, type_gid, id, options)
end

def create_private_collection(user, type_gid, id, options)
  options[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  create_collection(user, type_gid, id, options)
end

def create_collection(user, type_gid, id, options)
  col = Collection.where(id: id)
  return col.first if col.present?
  col = Collection.new(id: id)
  col.attributes = options.except(:visibility)
  col.apply_depositor_metadata(user.user_key)
  col.collection_type_gid = type_gid
  col.visibility = options[:visibility]
  col.save
  Hyrax::Collections::PermissionsCreateService.create_default(collection: col, creating_user: user)
  col
end

def create_public_work(user, id, options)
  options[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  create_work(user, id, options)
end

def create_authenticated_work(user, id, options)
  options[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
  create_work(user, id, options)
end

def create_private_work(user, id, options)
  options[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  create_work(user, id, options)
end

def create_work(user, id, options)
  work = GenericWork.where(id: id)
  return work.first if work.present?
  actor = Hyrax::CurationConcern.actor
  attributes_for_actor = options
  work = GenericWork.new(id: id)
  actor_environment = Hyrax::Actors::Environment.new(work, Ability.new(user), attributes_for_actor)
  actor.create(actor_environment)
  work
end

# ---------------------------------
# create seeded objects for QA
# ---------------------------------
puts 'Create users for QA'
User.create(Hydra.config.user_key_field => 'mgr1@example.com', email: 'mgr1@example.com', password: 'pppppp') # 6*p
User.create(Hydra.config.user_key_field => 'mgr2@example.com', email: 'mgr2@example.com', password: 'pppppp')
User.create(Hydra.config.user_key_field => 'dep1@example.com', email: 'dep1@example.com', password: 'pppppp')
User.create(Hydra.config.user_key_field => 'dep2@example.com', email: 'dep2@example.com', password: 'pppppp')
User.create(Hydra.config.user_key_field => 'vw1@example.com', email: 'vw1@example.com', password: 'pppppp')
User.create(Hydra.config.user_key_field => 'vw2@example.com', email: 'vw2@example.com', password: 'pppppp')

puts 'create collection types for QA'
_discoverable_gid = create_collection_type('discoverable_collection_type', title: 'Discoverable', description: 'Sample collection type allowing collections to be discovered.', discoverable: true).gid
_sharable_gid = create_collection_type('sharable_collection_type', title: 'Sharable', description: 'Sample collection type allowing collections to be shared.', sharable: true).gid
options = { title: 'Multi-membership', description: 'Sample collection type allowing works to belong to multiple collections.', allow_multiple_membership: true }
_multi_membership_gid = create_collection_type('multi_membership_collection_type', options)
_nestable_1_gid = create_collection_type('nestable_1_collection_type', title: 'Nestable 1', description: 'A sample collection type allowing nesting.', nestable: true).gid
_nestable_2_gid = create_collection_type('nestable_2_collection_type', title: 'Nestable 2', description: 'Another sample collection type allowing nesting.', nestable: true).gid

# -------------------------------------------------------------
# create seeded objects for collection nesting ad hoc testing
# -------------------------------------------------------------
puts 'Create users for collection nesting ad hoc testing'
user = User.create(Hydra.config.user_key_field => 'foo@example.com', email: 'foo@example.com', password: 'foobarbaz')

puts 'create collection types for collection nesting ad hoc testing'
options = { title: 'Nestable Collection', description: 'Sample collection type that allows nesting of collections.',
            nestable: true, discoverable: true, sharable: true, allow_multiple_membership: true }
nestable_gid = create_collection_type('nestable_collection', options).gid

options = { title: 'Non-Nestable Collection', description: 'Sample collection type that DOES NOT allow nesting of collections.',
            nestable: false, discoverable: true, sharable: true, allow_multiple_membership: true }
_nonnestable_gid = create_collection_type('nonnestable_collection', options).gid

puts 'create collections for collection nesting ad hoc testing'
pnc = create_public_collection(user, nestable_gid, 'pnc1', title: 'Public Nestable Collection', description: 'Public nestable collection for use in ad hoc tests.')
pc = create_public_collection(user, nestable_gid, 'pc1', title: 'A Parent Collection', description: 'Public collection that will be a parent of another collection.')
cc = create_public_collection(user, nestable_gid, 'cc1', title: 'A Child Collection', description: 'Public collection that will be a child of another collection.')
cc.member_of_collections = [pc]

puts 'Create works for collection nesting ad hoc testing'
3.times do |i|
  create_public_work(user, "pub_gw_#{i}", title: "Public #{i}",
                                          description: "Public work #{i} being added to the Public Nested Collection",
                                          member_of_collection_ids: [pnc.id])
end
2.times do |i|
  create_authenticated_work(user, "auth_gw_#{i}", title: "Authenticated #{i}",
                                                  description: "Authenticated work #{i} being added to the Parent Collection",
                                                  member_of_collection_ids: [pc.id])
end
1.times do |i|
  create_private_work(user, "priv_gw_#{i}", title: "Private #{i}",
                                            description: "Proviate work #{i} being added to the Child Collection",
                                            member_of_collection_ids: [cc.id])
end

# -----------------------------------------------------
# create seeded objects for embargo ad hoc testing
# -----------------------------------------------------
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
