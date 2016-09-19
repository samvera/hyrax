# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

user = User.create(email: 'foo@example.org', password: 'foobarbaz')

# Public
3.times do |i|
  GenericWork.create(title: ["Public #{i}"], read_groups: ['public']) do |work|
    work.apply_depositor_metadata(user)
  end
end

# Authenticated
2.times do |i|
  GenericWork.create(title: ["Authenticated #{i}"], read_groups: ['registered']) do |work|
    work.apply_depositor_metadata(user)
  end
end

# Private
1.times do |i|
  GenericWork.create(title: ["Private #{i}"]) do |work|
    work.apply_depositor_metadata(user)
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
