# frozen_string_literal: true

require 'rails_helper'

module Hyrax
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
      it 'is not valid without worktype' do
        counter_metric = build(:counter_metric, worktype: nil)
        expect(counter_metric).not_to be_valid
        expect(counter_metric.errors[:worktype]).to include("can't be blank")
      end

      it 'is not valid without date' do
        counter_metric = build(:counter_metric, date: nil)
        expect(counter_metric).not_to be_valid
        expect(counter_metric.errors[:date]).to include("can't be blank")
      end
    end
  end
end
