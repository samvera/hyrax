# frozen_string_literal: true

module Hyrax
  class CounterMetric < ApplicationRecord
    validates :work_id, :date, presence: true
  end
end
