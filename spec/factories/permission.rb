# frozen_string_literal: true
FactoryBot.define do
  factory :permission, class: "Hyrax::Permission" do
    agent { create(:user).id }
    mode  { :read }
  end
end
