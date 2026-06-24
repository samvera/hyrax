# frozen_string_literal: true

# The generic autocomplete authority for the `linked_record` compound picker,
# mounted at `/authorities/search/linked_record/:source`. The `:source` URL
# segment arrives as `params[:subauthority]`; the authority delegates the query
# to that registered Hyrax::CompoundLinkedRecordResolver source's `search` proc,
# so no per-source authority class is needed. Returns `{ id:, label:, value: }`
# rows (or [] for an unregistered / non-searchable source).
RSpec.describe Qa::Authorities::LinkedRecord do
  let(:service) { described_class.new }
  let(:controller) { instance_double(Qa::TermsController, params:) }
  let(:params) { ActionController::Parameters.new(q: 'ada', subauthority: 'stub_people') }

  before do
    Hyrax::CompoundLinkedRecordResolver.register(
      :stub_people,
      finder: ->(_id) {},
      label: ->(r) { r[:label] },
      path: ->(r) { "/stub_people/#{r[:id]}" },
      search: lambda { |q|
        [{ id: '7', label: 'Ada Lovelace', value: '7' }, { id: '8', label: 'Alan Turing', value: '8' }]
          .select { |row| row[:label].downcase.include?(q.to_s.downcase) }
      }
    )
  end

  after { Hyrax::CompoundLinkedRecordResolver.registry.delete(:stub_people) }

  describe '#search' do
    subject(:results) { service.search('ada', controller) }

    it 'delegates to the source named by params[:subauthority]' do
      expect(results).to contain_exactly(a_hash_including(id: '7', label: 'Ada Lovelace', value: '7'))
    end

    context 'when the source is unregistered' do
      let(:params) { ActionController::Parameters.new(q: 'ada', subauthority: 'nope') }

      it 'returns an empty list' do
        expect(results).to eq([])
      end
    end

    context 'when no source (subauthority) is given' do
      let(:params) { ActionController::Parameters.new(q: 'ada') }

      it 'returns an empty list' do
        expect(results).to eq([])
      end
    end
  end
end
