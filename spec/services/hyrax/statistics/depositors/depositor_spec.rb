RSpec.describe Hyrax::Statistics::Depositors::Depositor, :clean_repo do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:service) { described_class.new(user1) }

  describe '.works' do
    let(:depositor_object) { double(works: count) }
    let(:count) { 5 }

    it 'is a convenience method' do
      expect(described_class).to receive(:new).with(user1).and_return(depositor_object)
      expect(described_class.works(depositor: user1)).to eq(count)
    end
  end

  describe '.file_sets' do
    let(:depositor_object) { double(file_sets: count) }
    let(:count) { 5 }

    it 'is a convenience method' do
      expect(described_class).to receive(:new).with(user1).and_return(depositor_object)
      expect(described_class.file_sets(depositor: user1)).to eq(count)
    end
  end

  describe '.collections' do
    let(:depositor_object) { double(collections: count) }
    let(:count) { 5 }

    it 'is a convenience method' do
      expect(described_class).to receive(:new).with(user1).and_return(depositor_object)
      expect(described_class.collections(depositor: user1)).to eq(count)
    end
  end

  describe "#works" do
    let!(:work1) { create_for_repository(:work, user: user1) }
    let!(:work2) { create_for_repository(:work, user: user2) }

    subject { service.works }

    it { is_expected.to eq 1 }
  end

  describe "#file_sets" do
    let!(:file_set1) { create_for_repository(:file_set, user: user1) }
    let!(:file_set2) { create_for_repository(:file_set, user: user2) }

    subject { service.file_sets }

    it { is_expected.to eq 1 }
  end

  describe "#collections" do
    let!(:collection1) { create_for_repository(:collection, :public, user: user1) }
    let!(:collection2) { create_for_repository(:collection, :public, user: user2) }

    subject { service.collections }

    it { is_expected.to eq 1 }
  end
end
