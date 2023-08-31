# frozen_string_literal: true
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#
# To use this file, run the following command in the test app:
#   rails generate hyrax:sample_data
#
# To re-use this file, you will likely want to clean out the test app content
#   rails console
#     require 'active_fedora/cleaner'
#     ActiveFedora::Cleaner.clean!
#     exit
#   rake db:drop db:create db:migrate
#   rake db:seed

Hyrax::Engine.load_seed

# ---------------------------------
# methods to create various objects
# ---------------------------------
def create_user(email, pw)
  # user = User.find_or_create_by(email: email) do |user|
  user = User.find_or_create_by(Hydra.config.user_key_field => email) do |u|
    u.email = email
    u.password = pw
    u.password_confirmation = pw
  end
  user
end

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

def collection_attributes_for(collection_ids)
  attrs = {}
  0.upto(collection_ids.size) { |i| attrs[i.to_s] = { 'id' => collection_ids[i] } }
  attrs
end

puts "---------------------------------"
puts " Create seeded objects for QA"
puts "---------------------------------"
puts 'Create users for QA'
create_user('mgr1@example.com', 'pppppp') # 6*p
create_user('mgr2@example.com', 'pppppp')
create_user('dep1@example.com', 'pppppp')
create_user('dep2@example.com', 'pppppp')
create_user('vw1@example.com', 'pppppp')
create_user('vw2@example.com', 'pppppp')
genuser = create_user('general_user@example.com', 'pppppp')

puts 'Create collection types for QA'
_discoverable_gid = create_collection_type('discoverable_collection_type', title: 'Discoverable', description: 'Sample collection type allowing collections to be discovered.', discoverable: true)
                    .to_global_id
_sharable_gid = create_collection_type('sharable_collection_type', title: 'Sharable', description: 'Sample collection type allowing collections to be shared.', sharable: true).to_global_id
options = { title: 'Multi-membership', description: 'Sample collection type allowing works to belong to multiple collections.', allow_multiple_membership: true }
_multi_membership_gid = create_collection_type('multi_membership_collection_type', options)
_nestable_1_gid = create_collection_type('nestable_1_collection_type', title: 'Nestable 1', description: 'A sample collection type allowing nesting.', nestable: true).to_global_id
_nestable_2_gid = create_collection_type('nestable_2_collection_type', title: 'Nestable 2', description: 'Another sample collection type allowing nesting.', nestable: true).to_global_id
_empty_gid = create_collection_type('empty_collection_type', title: 'Test Empty Collection Type', description: 'A collection type with 0 collections of this type').to_global_id
inuse_gid = create_collection_type('inuse_collection_type', title: 'Test In-Use Collection Type', description: 'A collection type with at least one collection of this type').to_global_id

puts 'Create collections for QA'
inuse_col = create_public_collection(genuser, inuse_gid, 'inuse_col1', title: ['Public Collection of type In-Use'], description: ['Public collection of the type Test In-Use Collection Type.'])

puts 'create works for QA'
3.times do |i|
  create_public_work(genuser, "qa_pu_gw_#{i}",
                     title: ["QA Public #{i}"],
                     description: ["Public work #{i} for QA testing"],
                     creator: ['Joan Smith'], keyword: ['test'], rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                     member_of_collections_attributes: collection_attributes_for([inuse_col.id]))
end
2.times do |i|
  create_authenticated_work(genuser, "qa_auth_gw_#{i}",
                            title: ["QA Authenticated #{i}"],
                            description: ["Authenticated work #{i} for QA testing"],
                            creator: ['John Smith'], keyword: ['test'], rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                            member_of_collections_attributes: collection_attributes_for([inuse_col.id]))
end
1.times do |i|
  create_private_work(genuser, "qa_priv_gw_#{i}",
                      title: ["QA Private #{i}"],
                      description: ["Proviate work #{i} for QA testing"],
                      creator: ['Jean Smith'], keyword: ['test'], rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                      member_of_collections_attributes: collection_attributes_for([inuse_col.id]))
end

puts "-------------------------------------------------------------"
puts " Create seeded objects for collection nesting ad hoc testing"
puts "-------------------------------------------------------------"
puts 'Create users for collection nesting ad hoc testing'
user = create_user('foo@example.com', 'foobarbaz')

puts 'Create collection types for collection nesting ad hoc testing'
options = { title: 'Nestable Collection', description: 'Sample collection type that allows nesting of collections.',
            nestable: true, discoverable: true, sharable: true, allow_multiple_membership: true }
nestable_gid = create_collection_type('nestable_collection', options).to_global_id

options = { title: 'Non-Nestable Collection', description: 'Sample collection type that DOES NOT allow nesting of collections.',
            nestable: false, discoverable: true, sharable: true, allow_multiple_membership: true }
_nonnestable_gid = create_collection_type('nonnestable_collection', options).to_global_id

puts 'Create collections for collection nesting ad hoc testing'
pnc = create_public_collection(user, nestable_gid, 'public_nestable', title: ['Public Nestable Collection'], description: ['Public nestable collection for use in ad hoc tests.'])
pc = create_public_collection(user, nestable_gid, 'parent_nested', title: ['A Parent Collection'], description: ['Public collection that will be a parent of another collection.'])
cc = create_public_collection(user, nestable_gid, 'child_nested', title: ['A Child Collection'], description: ['Public collection that will be a child of another collection.'])
Hyrax::Collections::NestedCollectionPersistenceService.persist_nested_collection_for(parent: pc, child: cc)

puts 'Create collection with many child collections and works'
mpc = create_public_collection(
  user,
  nestable_gid,
  'parent_nested_many',
  title: ['A Parent Collection with many Child Collections'],
  description: ['Public collection that will be a parent of many collections.']
)
21.times do |i|
  mcc = create_public_collection(user, nestable_gid, "child_nested_#{i}", title: ["Child Collection #{i}"], description: ['Public collection that will be a child of another collection.'])
  Hyrax::Collections::NestedCollectionPersistenceService.persist_nested_collection_for(parent: mpc, child: mcc)
  create_public_work(user, "pub_mgw_#{i}",
                     title: ["Public #{i}"],
                     description: ["Public work #{i} being added to the Public Nested Collection"],
                     creator: ['Joan Smith'], keyword: ['test'], rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                     member_of_collections_attributes: collection_attributes_for([mpc.id]))
end

puts 'Create collections with many parent collections'
# Pool of collections that will be used as parents of the collections
parent_pool = Array.new(12) do |i|
  create_public_collection(user,
                           nestable_gid,
                           "col_shared_parents_#{i}",
                           title: ["Shared Parent collection #{i}"],
                           description: ['Collection that shares children with multiple parents.'])
end
# 2 parent collection
col_two_parents = create_public_collection(user, nestable_gid, "col_two_parents", title: ["Collection - 2 parents"], description: ['Collection that has two parents.'])
2.times { |i| Hyrax::Collections::NestedCollectionPersistenceService.persist_nested_collection_for(parent: parent_pool[i], child: col_two_parents) }
# 6 parent collection
col_six_parents = create_public_collection(user, nestable_gid, "col_six_parents", title: ["Collection - 6 parents"], description: ['Collection that has six parents.'])
6.times { |i| Hyrax::Collections::NestedCollectionPersistenceService.persist_nested_collection_for(parent: parent_pool[i], child: col_six_parents) }
# 12 parent collection
col_twelve_parents = create_public_collection(user, nestable_gid, "col_twelve_parents", title: ["Collection - 12 parents"], description: ['Collection that has twelve parents.'])
12.times { |i| Hyrax::Collections::NestedCollectionPersistenceService.persist_nested_collection_for(parent: parent_pool[i], child: col_twelve_parents) }

puts 'Create works for collection nesting ad hoc testing'
3.times do |i|
  create_public_work(user, "pub_gw_#{i}",
                     title: ["Public #{i}"],
                     description: ["Public work #{i} being added to the Public Nested Collection"],
                     creator: ['Joan Smith'], keyword: ['test'], rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                     member_of_collections_attributes: collection_attributes_for([pnc.id]))
end
2.times do |i|
  create_authenticated_work(user, "auth_gw_#{i}",
                            title: ["Authenticated #{i}"],
                            description: ["Authenticated work #{i} being added to the Parent Collection"],
                            creator: ['John Smith'], keyword: ['test'], rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                            member_of_collections_attributes: collection_attributes_for([pc.id]))
end
1.times do |i|
  create_private_work(user, "priv_gw_#{i}",
                      title: ["Private #{i}"],
                      description: ["Proviate work #{i} being added to the Child Collection"],
                      creator: ['Jean Smith'], keyword: ['test'], rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                      member_of_collections_attributes: collection_attributes_for([cc.id]))
end

puts "-----------------------------------------------------"
puts " Create seeded objects for embargo ad hoc testing"
puts "-----------------------------------------------------"
# TODO: update to use create_work method which uses actor stack to create works

puts 'Create Active, Private Embargo works'
3.times do |i|
  GenericWork.create(title: ["Active Private #{i}"]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_embargo(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
  end
end

puts 'Create Active, Authenticated Embargo works'
2.times do |i|
  GenericWork.create(title: ["Active Authenticated #{i}"]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_embargo(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
  end
end

puts 'Create Expired, Authenticated Embargo works'
1.times do |i|
  GenericWork.create(title: ["Expired Authenticated #{i}"], read_groups: [Hyrax.config.registered_user_group_name]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_embargo(Date.yesterday.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
  end
end

puts 'Create Expired, Public Embargo works'
3.times do |i|
  GenericWork.create(title: ["Expired Public #{i}"], read_groups: [Hyrax.config.public_user_group_name]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_embargo(Date.yesterday.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
  end
end

puts 'Create Active, Public Lease works'
3.times do |i|
  GenericWork.create(title: ["Active Public #{i}"], read_groups: [Hyrax.config.public_user_group_name]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_lease(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
  end
end

puts 'Create Active, Authenticated Lease works'
2.times do |i|
  GenericWork.create(title: ["Active Authenticated #{i}"], read_groups: [Hyrax.config.registered_user_group_name]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_lease(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
  end
end

puts 'Create Expired, Authenticated Lease works'
1.times do |i|
  GenericWork.create(title: ["Expired Authenticated #{i}"], read_groups: [Hyrax.config.registered_user_group_name]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_lease(Date.yesterday.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
  end
end

puts 'Create Expired, Private Lease works'
3.times do |i|
  GenericWork.create(title: ["Expired Public #{i}"]) do |work|
    work.apply_depositor_metadata(user)
    work.apply_lease(Date.yesterday.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
  end
end
