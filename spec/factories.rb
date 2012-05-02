FactoryGirl.define do
  factory :user, :class=>User do |u|
    login "jilluser"
  end

  factory :archivist, :class=>User do |u|
    login "archivist1"
  end  
end

