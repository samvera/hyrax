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
  end
end
