# frozen_string_literal: true
RSpec.describe Hyrax::ChartsHelper do
  describe '#hash_to_chart' do
    subject { helper.hash_to_chart(data) }

    let(:data) do
      {
        'Foo' => 5,
        'Bar' => 10
      }
    end

    it do
      is_expected.to eq(
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
    end
    context "given a drilldown" do
      let(:data) do
        {
          "Foo" => {
            "Bar" => 1,
            "Baz" => 2
          }
        }
      end

      it do
        is_expected.to eq(
          drilldown: {
            series: [
              {
                name: "Foo",
                id: "Foo",
                data: [["Bar", 1], ["Baz", 2]]
              }
            ]
          },
          series:
          [
            {
              name: "Foo",
              y: 3,
              drilldown: "Foo"
            }
          ]
        )
      end
    end
  end
end
