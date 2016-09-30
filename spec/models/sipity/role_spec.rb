require 'spec_helper'

module Sipity
  RSpec.describe Role, type: :model, no_clean: true do
    context 'class methods' do
      subject { described_class }
      its(:column_names) { is_expected.to include('name') }
      its(:column_names) { is_expected.to include('description') }
      context '.[]' do
        let(:valid_name) { 'reviewing' }

        it 'will find the named role' do
          expected_object = described_class.create!(name: valid_name)
          expect(described_class[valid_name]).to eq(expected_object)
        end

        it 'will created the named role' do
          expect { described_class[valid_name].name }.to change { described_class.count }.by(1)
        end
      end
    end

    subject { described_class.new }

    it 'will have a #to_s that is a name' do
      subject.name = 'advising'
      expect(subject.to_s).to eq(subject.name)
    end
  end
end
