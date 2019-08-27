# frozen_string_literal: true
FactoryBot.define do
  factory :permission, class: "Hyrax::Permission" do
    agent { create(:user).id.to_s }
    mode  { :read }
  end
end
