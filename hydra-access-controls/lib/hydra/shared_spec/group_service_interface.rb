RSpec.shared_examples 'a Hydra group_service interface' do
  before do
    raise 'adapter must be set with `let(:group_service)`' unless
      defined? group_service
  end

  subject { group_service }

  it { is_expected.to respond_to(:role_names).with(0).arguments }

  describe '#fetch_groups' do
    it 'requires a user: keyword arg' do
      expect(group_service.method(:fetch_groups).parameters).to eq([[:keyreq, :user]])
    end
  end
end
