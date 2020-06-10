# frozen_string_literal: true

require "spec_helper"

module Sipity
  RSpec.describe WorkflowAction, type: :model do
    context 'database configuration' do
      subject { described_class }

      its(:column_names) { is_expected.to include('workflow_id') }
      its(:column_names) { is_expected.to include('resulting_workflow_state_id') }
      its(:column_names) { is_expected.to include('name') }
    end

    describe '.name' do
      [
        [:show, 'show'],
        [:show?, 'show'],
        [:new?, 'new'],
        [:new, 'new'],
        [:edit?, 'edit'],
        [:edit, 'edit'],
        [:submit, 'submit'],
        [:submit?, 'submit'],
        [:attach, 'attach'],
        [described_class.new(name: 'hello'), 'hello']
      ].each_with_index do |(original, expected), index|
        it "will convert #{original.inspect} to #{expected.inspect} (scenario ##{index})" do
          expect(described_class.name_for(original)).to eq(expected)
        end
      end
    end

    it 'will raise an exception if it is not processible' do
      object = double('Bad Wolf')
      expect { described_class.name_for(object) }.to raise_error(Sipity::ConversionError)
    end

    it 'will leverage a short-circuit #to_processing_action_name' do
      object = double(to_sipity_action_name: 'bob')
      expect(described_class.name_for(object)).to eq('bob')
    end
  end
end
