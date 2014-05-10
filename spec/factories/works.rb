# Class that exemplifies the essential characteristics of a CurationConcern::Work
class EssentialWork < ActiveFedora::Base
  include CurationConcern::Work 
end

FactoryGirl.define do
  factory :essential_work, class: EssentialWork do
    ignore do
      user {FactoryGirl.create(:user)}
    end

    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    before(:create) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end
    

    factory :public_essential_work do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    factory :essential_work_with_files do
      after(:build) { |work, evaluator| 2.times { work.generic_files << FactoryGirl.build(:generic_file) }}
    end
  end
end
