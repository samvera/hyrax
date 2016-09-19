require 'spec_helper'

describe CurationConcerns::ChartsHelper do
  describe '#hash_to_chart' do
    subject { helper.hash_to_chart(data) }
    let(:data) do
      {
        'Foo' => 5,
        'Bar' => 10
      }
    end
    it { is_expected.to eq(
      drilldown: {
        series: []
      },
      series:
[
  {
    name: "Foo",
    y: 5
  },
  {
    name: "Bar",
    y: 10
  }
]
    )
    }
  end
end
