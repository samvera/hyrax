RSpec.describe Hyrax::Admin::UserActivityPresenter do
  let(:instance) { described_class.new }

  describe "#to_json" do
    subject { instance.to_json }

    let(:unique_visitors) do
      instance_double(Hyrax::Statistics::Site::UniqueVisitors,
                      points: [["Feb 21", 0], ["Feb 28", 20], ["Mar 7", 10]])
    end

    let(:returning_visitors) do
      instance_double(Hyrax::Statistics::Site::ReturningVisitors,
                      points: [["Feb 21", 5], ["Feb 28", 10], ["Mar 7", 0]])
    end

    before do
      allow(Hyrax::Statistics::Site::UniqueVisitors).to receive(:new).and_return(unique_visitors)
      allow(Hyrax::Statistics::Site::ReturningVisitors).to receive(:new).and_return(returning_visitors)
    end

    it "returns points" do
      expect(subject).to eq '[{"name":"New Visitors","data":[["Feb 21",0],["Feb 28",20],["Mar 7",10]]},{"name":"Returning Visitors","data":[["Feb 21",5],["Feb 28",10],["Mar 7",0]]}]'
    end
  end
end
