RSpec.describe Hyrax::Admin::RepositoryGrowthPresenter do
  let(:instance) { described_class.new }

  describe "#to_json action" do
    subject { instance.to_json }

    let(:works) do
      instance_double(Hyrax::Statistics::Works::OverTime,
                      points: [['2017-02-16', '12']])
    end
    let(:collections) do
      instance_double(Hyrax::Statistics::Collections::OverTime,
                      points: [['2017-02-16', '3']])
    end

    before do
      allow(Hyrax::Statistics::Works::OverTime).to receive(:new).and_return(works)
      allow(Hyrax::Statistics::Collections::OverTime).to receive(:new).and_return(collections)
    end

    it "returns points" do
      expect(subject).to eq '[{"name":"Works","data":[["2017-02-16","12"]]},{"name":"Collections","data":[["2017-02-16","3"]]}]'
    end
  end
end
