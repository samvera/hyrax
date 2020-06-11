# frozen_string_literal: true
RSpec.describe Hyrax::TolerantSelectService do
  subject(:select_service) { described_class.new(authority_name) }

  let(:authority) { FakeAuthority }
  let(:authority_name) { 'fake_authority' }
  let(:authority_map) { [] }

  before do
    allow(Qa::Authorities::Local)
      .to receive(:subauthority_for)
      .with(authority_name)
      .and_return(authority.new(authority_map))
  end

  shared_context 'with terms' do
    let(:authority_map) do
      [HashWithIndifferentAccess.new(term: 'Active Label', label: 'Active Label', id: 'active-id', active: true),
       HashWithIndifferentAccess.new(term: 'Inactive Label', label: 'Inactive Label', id: 'inactive-id', active: false),
       HashWithIndifferentAccess.new(label: 'Active No Term', id: 'active-no-term-id', active: true),
       HashWithIndifferentAccess.new(term: 'No Active Flag Term', label: 'No Active Flag Label', id: 'no-active-flag-id')]
    end
  end

  describe '#active?' do
    it 'is false for missing id' do
      expect(select_service.active?('fake_id')).to be_falsey
    end

    context 'with terms' do
      include_context 'with terms'

      it 'is true for an active term' do
        expect(select_service.active?('active-id')).to be true
      end

      it 'is false for an inactive term' do
        expect(select_service.active?('inactive-id')).to be_falsey
      end

      it 'defaults to true for a term with no flag' do
        expect(select_service.active?('no-active-flag-id')).to be true
      end
    end
  end

  describe '#select_all_options' do
    it 'is empty' do
      expect(select_service.select_all_options).to be_empty
    end

    context 'with terms' do
      include_context 'with terms'

      it 'contains all labels and ids' do
        expect(select_service.select_all_options)
          .to contain_exactly(['Active Label', 'active-id'],
                              ['Inactive Label', 'inactive-id'],
                              ['Active No Term', 'active-no-term-id'],
                              ['No Active Flag Label', 'no-active-flag-id'])
      end
    end
  end

  describe '#select_active_options' do
    it 'is empty' do
      expect(select_service.select_active_options).to be_empty
    end

    context 'with terms' do
      include_context 'with terms'

      it 'contains active labels and ids' do
        expect(select_service.select_active_options)
          .to contain_exactly(['Active Label', 'active-id'],
                              ['Active No Term', 'active-no-term-id'],
                              ['No Active Flag Label', 'no-active-flag-id'])
      end
    end
  end
end
