# TODO: this should be expanded to offer better coverage including primary_terms
# and secondary_terms once these features are supported
RSpec.describe Hyrax::GenericWorkChangeSet do
  subject(:change_set) { described_class.new(work) }

  let(:work) { GenericWork.new }

  describe "validations" do
    it "is valid by default" do
      expect(change_set).to be_valid
    end
  end

  describe "#fields" do
    subject { change_set.fields.keys }

    it { is_expected.to eq ['resource_type'] }
  end
end
