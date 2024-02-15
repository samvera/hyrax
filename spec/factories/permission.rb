# frozen_string_literal: true
FactoryBot.define do
  factory :permission, class: "Hyrax::Permission" do
    agent { create(Hyrax::Specs::FactoryName.user).user_key.to_s }
    mode  { :read }
  end
end
