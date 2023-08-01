# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

# TODO: These tests pass locally, but are being skipped because they fail in CI.
# The failure in CI is related to new migrations not being added correctly inside the internal_test_app.
# Once https://github.com/samvera/hyrax/issues/6125 is completed, these tests should pass in CI and can be unskipped.
RSpec.describe Hyrax::CounterMetric, type: :model do
  context 'validations' do
    xit 'is valid with valid attributes' do
      counter_metric = build(:counter_metric)
      expect(counter_metric).to be_valid
    end
  end

  context 'required fields' do
    xit 'is not valid without work_id' do
      counter_metric = build(:counter_metric, work_id: nil)
      expect(counter_metric).not_to be_valid
      expect(counter_metric.errors[:work_id]).to include("can't be blank")
    end

    xit 'is not valid without date' do
      counter_metric = build(:counter_metric, date: nil)
      expect(counter_metric).not_to be_valid
      expect(counter_metric.errors[:date]).to include("can't be blank")
    end
  end
end
