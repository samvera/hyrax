# frozen_string_literal: true
RSpec.describe Qa::Authorities::CompoundWorks, :clean_repo do
  let(:controller) { Qa::TermsController.new }
  let(:user) { create(:user) }
  let(:ability) { instance_double(Ability, admin?: false, user_groups: ['public', 'registered'], current_user: user) }
  let(:q) { "journal" }
  let(:params) do
    ActionController::Parameters.new(q: q, user: user.user_key,
                                     controller: "qa/terms", action: "search", vocab: "compound_works")
  end
  let(:service) { described_class.new }
  let!(:journal) { valkyrie_create(:monograph, :public, title: ['Journal of Practice Research']) }
  let!(:other)   { valkyrie_create(:monograph, :public, title: ['Unrelated Book']) }

  before do
    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:current_ability).and_return(ability)
  end

  subject { service.search(q, controller) }

  describe '#search' do
    before { allow(controller).to receive(:current_user).and_return(user) }

    it 'returns readable works matched by a partial title' do
      expect(subject.map { |result| result[:id] }).to include(journal.id)
      expect(subject.map { |result| result[:id] }).not_to include(other.id)
    end

    it 'shapes each result as { id:, label:, value: }' do
      result = subject.find { |r| r[:id] == journal.id }
      expect(result).to include(id: journal.id, label: 'Journal of Practice Research', value: journal.id)
    end
  end

  describe '#search without a current user' do
    before { allow(controller).to receive(:current_user).and_return(nil) }

    it 'returns an empty list' do
      expect(subject).to eq([])
    end
  end
end
