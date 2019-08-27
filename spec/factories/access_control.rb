# frozen_string_literal: true
FactoryBot.define do
  factory :access_control, class: Hyrax::AccessControl do
    permissions { build(:permission) }
  end
end
