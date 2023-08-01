# frozen_string_literal: true

FactoryBot.define do
  factory :counter_metric, class: "Hyrax::CounterMetric" do
    worktype { "Generic Work" }
    resource_type { "Book" }
    work_id { "12345678" }
    date { Date.new(2023, 7, 17) }
    total_item_investigations { 10 }
    total_item_requests { 5 }
  end
end
