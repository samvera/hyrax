RSpec.describe Hyrax::Admin::UserActivityPresenter do
  let(:instance) { described_class.new }

  describe "#to_json" do
    subject { instance.to_json }

    let(:visitors) do
      instance_double(Hyrax::Statistics::Site::Visitors,
                      points: [["Feb 21", 0], ["Feb 28", 20], ["Mar 7", 10]])
    end

    let(:sessions) do
      instance_double(Hyrax::Statistics::Site::Sessions,
                      points: [["Feb 21", 5], ["Feb 28", 10], ["Mar 7", 0]])
    end

    before do
      allow(Hyrax::Statistics::Site::Visitors).to receive(:new).and_return(visitors)
      allow(Hyrax::Statistics::Site::Sessions).to receive(:new).and_return(sessions)
    end

    it "returns points" do
      expect(subject).to eq '[{"name":"Visitors","data":[["Feb 21",0],["Feb 28",20],["Mar 7",10]]},{"name":"Sessions","data":[["Feb 21",5],["Feb 28",10],["Mar 7",0]]}]'
    end
  end
end
