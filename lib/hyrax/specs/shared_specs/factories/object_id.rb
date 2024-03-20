# frozen_string_literal: true
# Defines a new sequence
FactoryBot.define do
  sequence :object_id do |n|
    "object_id_#{n}"
  end
end
