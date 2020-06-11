# frozen_string_literal: true
RSpec.describe Hyrax::QaSelectService do
  let(:authority_map) do
    [
      HashWithIndifferentAccess.new(term: 'Active Label', label: 'Active Label', id: 'active-id', active: true),
      HashWithIndifferentAccess.new(term: 'Inactive Label', label: 'Inactive Label', id: 'inactive-id', active: false),
      HashWithIndifferentAccess.new(label: 'Active No Term', id: 'active-no-term-id', active: true)
    ]
  end

  let(:authority) { FakeAuthority }
  let(:authority_name) { 'respect_my' }
  let(:qa_select_service) { described_class.new(authority_name) }

  before do
    allow(Qa::Authorities::Local).to receive(:subauthority_for).with(authority_name).and_return(authority.new(authority_map))
  end

  describe '#select_all_options' do
    subject { qa_select_service.select_all_options }

    it 'will be Array of Arrays<label, id>' do
      expect(subject).to eq([['Active Label', 'active-id'], ['Inactive Label', 'inactive-id'], ['Active No Term', 'active-no-term-id']])
    end
  end

  describe '#select_active_options' do
    subject { qa_select_service.select_active_options }

    it 'will be Array of Arrays<label, id>' do
      expect(subject).to eq([['Active Label', 'active-id'], ['Active No Term', 'active-no-term-id']])
    end

    context 'when a key has no active property' do
      let(:no_state) { HashWithIndifferentAccess.new(term: 'term', label: 'label', id: 'no-state') }

      before { authority_map << no_state }

      it 'raises KeyError' do
        expect { subject }.to raise_error(KeyError)
      end
    end
  end

  describe '#label' do
    context 'for item with a "term" propery' do
      subject { qa_select_service.label('active-id') }

      it { is_expected.to be_a(String) }
    end
    context 'for item without a "term" property' do
      it 'will raise KeyError' do
        expect { qa_select_service.label('active-no-term-id') }
          .to raise_error(KeyError)
      end

      it 'accepts a block for a backup value' do
        expect(qa_select_service.label('active-no-term-id') { :backup })
          .to eq :backup
      end
    end
  end

  describe '#active?' do
    context 'for item with an "active" property' do
      subject { qa_select_service.active?('active-id') }

      it { is_expected.to be_truthy }
    end
    context 'for item without an "active" property' do
      let(:authority_map) do
        [
          HashWithIndifferentAccess.new(term: 'term', label: 'label', id: 'with-term-no-active-state-id')
        ]
      end

      it 'will raise KeyError' do
        expect { qa_select_service.active?('with-term-no-active-state-id') }.to raise_error(KeyError)
      end
    end
  end

  describe '#include_current_value' do
    let(:render_opts) { [] }
    let(:html_opts)   { { class: 'moomin' } }

    let(:authority_map) do
      [
        HashWithIndifferentAccess.new(term: 'Active Label', label: 'Active Label', id: 'active-id', active: true),
        HashWithIndifferentAccess.new(term: 'Inactive Label', label: 'Inactive Label', id: 'inactive-id', active: false),
        HashWithIndifferentAccess.new(label: 'Inactive No Term', id: 'inactive-no-term-id', active: false)
      ]
    end

    it 'adds an inactive current value' do
      expect(qa_select_service.include_current_value('inactive-id', :idx, render_opts, html_opts))
        .to eq [[['Inactive Label', 'inactive-id']], { class: 'moomin force-select' }]
    end

    it 'adds an inactive current value with fallback label' do
      expect(qa_select_service.include_current_value('inactive-no-term-id', :idx, render_opts, html_opts))
        .to eq [[['inactive-no-term-id', 'inactive-no-term-id']], { class: 'moomin force-select' }]
    end

    it 'does not add an active current value' do
      expect(qa_select_service.include_current_value('active-id', :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
    end
  end
end
