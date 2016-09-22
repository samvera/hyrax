require 'spec_helper'

describe CurationConcerns::ChartsHelper do
  describe '#hash_to_flot' do
    subject { helper.hash_to_flot(data) }
    let(:data) do
      {
        'Foo' => 5,
        'Bar' => 10
      }
    end
    it { is_expected.to eq([{ label: 'Foo', data: 5 }, { label: 'Bar', data: 10 }]) }
  end
end
