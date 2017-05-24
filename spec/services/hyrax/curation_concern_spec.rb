RSpec.describe Hyrax::CurationConcern do
  let(:work) { GenericWork.new }
  let(:user) { double(current_user: double) }

  describe ".actor" do
    subject { described_class.actor }
    it { is_expected.to be_kind_of Hyrax::Actors::TransactionalRequest }
  end
end
