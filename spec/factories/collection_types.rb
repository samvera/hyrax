FactoryGirl.define do
  factory :collection_type, class: Hyrax::CollectionType do
    sequence(:id) { |n| n }
    sequence(:title) { |n| "Title #{n}" }
    description 'Collection type with all options'
    nestable true
    discoverable true
    sharable true
    allow_multiple_membership true
    require_membership false
    assigns_workflow false
    assigns_visibility false

    factory :user_collection_type do
      title 'User Collection'
      description 'A user oriented collection type'
    end
  end
end
