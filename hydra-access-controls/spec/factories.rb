FactoryGirl.define do

  # Users

  # Prototype user factory
  factory :user, :aliases => [:owner] do |u|
    sequence :uid do |n|
      "person#{n}"
    end
    password { uid }
  end

  factory :archivist, :parent=>:user do |u|
    uid 'archivist1'
    password 'archivist1'
  end
  factory :registered_user, :parent=>:user do |u|
    uid 'registered_user'
    password 'registered_user'
  end
  factory :staff, :parent=>:user do |u|
    uid 'staff1'
    password 'staff1'
  end
  factory :student, :parent=>:user do |u|
    uid 'student1'
    password 'student1'
  end
  factory :joe_creator, :parent=>:user do |u|
    uid 'joe_creator'
    password 'joe_creator'
  end
  factory :martia_morocco, :parent=>:user do |u|
    uid 'martia_morocco'
    password 'martia_morocco'
  end
  factory :ira_instructor, :parent=>:user do |u|
    uid 'ira_instructor'
    password 'ira_instructor'
  end
  factory :calvin_collaborator, :parent=>:user do |u|
    uid 'calvin_collaborator'
    password 'calvin_collaborator'
  end
  factory :sara_student, :parent=>:user do |u|
    uid 'sara_student'
    password 'sara_student'
  end
  factory :louis_librarian, :parent=>:user do |u|
    uid 'louis_librarian'
    password 'louis_librarian'
  end
  factory :carol_curator, :parent=>:user do |u|
    uid 'carol_curator'
    password 'carol_curator'
  end
  factory :alice_admin, :parent=>:user do |u|
    uid 'alice_admin'
    password 'alice_admin'
  end

  #
  # Repository Objects
  #

  factory :asset, :class => ModsAsset do |o|
  end

  factory :admin_policy, :class => Hydra::AdminPolicy do |o|
  end

  factory :default_access_asset, :parent=>:asset do |a|
    permissions_attributes [{ name: "joe_creator", access: "edit", type: "person" }]
  end

  factory :dept_access_asset, :parent=>:asset do |a|
    permissions_attributes [{ name: "africana-faculty", access: "read", type: "group" }, { name: "joe_creator", access: "edit", type: "person" }]
  end

  factory :group_edit_asset, :parent=>:asset do |a|
    permissions_attributes [{ name:"africana-faculty", access: "edit", type: "group" }, {name: "calvin_collaborator", access: "edit", type: "person"}]
  end

  factory :org_read_access_asset, :parent=>:asset do |a|
    permissions_attributes [{ name: "registered", access: "read", type: "group" }, { name: "joe_creator", access: "edit", type: "person" }, { name: "calvin_collaborator", access: "edit", type: "person" }]
  end

  factory :open_access_asset, :parent=>:asset do |a|
    permissions_attributes [{ name: "public", access: "read", type: "group" }, { name: "joe_creator", access: "edit", type: "person" }, { name: "calvin_collaborator", access: "edit", type: "person" }]
  end

end

