# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

RSpec.describe Hyrax::CounterMetric, type: :model do
  context 'validations' do
    it 'is valid with valid attributes' do
      counter_metric = build(:counter_metric)
      expect(counter_metric).to be_valid
    end
  end

  context 'required fields' do
    it 'is not valid without work_id' do
      counter_metric = build(:counter_metric, work_id: nil)
      expect(counter_metric).not_to be_valid
      expect(counter_metric.errors[:work_id]).to include("can't be blank")
    end

    it 'is not valid without date' do
      counter_metric = build(:counter_metric, date: nil)
      expect(counter_metric).not_to be_valid
      expect(counter_metric.errors[:date]).to include("can't be blank")
    end
  end
end
