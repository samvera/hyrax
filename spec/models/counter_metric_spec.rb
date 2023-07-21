# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterMetric, type: :model do
  context 'validations' do
    it 'is valid with valid attributes' do
      counter_metric = build(:counter_metric)
      expect(counter_metric).to be_valid
    end
  end

  # TODO: figure out which fields are required,
  # add any validations to the model, unskip these + add any other required fields
  context 'required fields' do
    xit 'is not valid without worktype' do
      counter_metric = build(:counter_metric, worktype: nil)
      expect(counter_metric).not_to be_valid
      expect(counter_metric.errors[:worktype]).to include("can't be blank")
    end

    xit 'is not valid without resource_type' do
      counter_metric = build(:counter_metric, resource_type: nil)
      expect(counter_metric).not_to be_valid
      expect(counter_metric.errors[:resource_type]).to include("can't be blank")
    end

    # Repeat similar tests for other required fields (work_id, date, total_item_investigations, total_item_requests)
  end
end
