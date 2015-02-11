FactoryGirl.define do
  factory :linked_resource, class: Worthwhile::LinkedResource  do
    transient do
      user {FactoryGirl.create(:user)}
    end
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    url 'http://www.youtube.com/watch?v=oHg5SJYRHA0'
    batch { FactoryGirl.create(:generic_work, user: user) }
    before(:create) { |file, evaluator|
      file.apply_depositor_metadata(evaluator.user.user_key)
    }

    factory :private_linked_resource do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

  end
end
