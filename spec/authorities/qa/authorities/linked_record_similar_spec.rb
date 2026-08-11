# frozen_string_literal: true

# The generic "did you mean" authority for the `linked_record` compound picker's
# create-form duplicate check, mounted at
# `/authorities/search/linked_record_similar/:source`. The `:source` URL segment
# arrives as `params[:subauthority]`; the authority delegates the typed name to
# that registered Hyrax::CompoundLinkedRecordResolver source's `similar` proc, so
# no per-source authority class is needed. Returns `{ id:, label:, value: }` rows
# (or [] for an unregistered source or one with no similar proc). Sibling of
# Qa::Authorities::LinkedRecord (the typeahead authority).
RSpec.describe Qa::Authorities::LinkedRecordSimilar do
  let(:service) { described_class.new }
  let(:controller) { instance_double(Qa::TermsController, params:) }
  let(:params) { ActionController::Parameters.new(q: 'Ada Byron', subauthority: 'stub_people') }

  before do
    Hyrax::CompoundLinkedRecordResolver.register(
      :stub_people,
      finder: ->(_id) {},
      label: ->(r) { r[:label] },
      path: ->(r) { "/stub_people/#{r[:id]}" },
      # Fuzzy stub: match on a shared first token so "Ada Byron" surfaces "Ada Lovelace".
      similar: lambda { |q|
        token = q.to_s.downcase.split.first.to_s
        [{ id: '7', label: 'Ada Lovelace', value: '7' }, { id: '8', label: 'Alan Turing', value: '8' }]
          .select { |row| row[:label].downcase.include?(token) }
      }
    )
  end

  after { Hyrax::CompoundLinkedRecordResolver.registry.delete(:stub_people) }

  describe '#search' do
    subject(:results) { service.search('Ada Byron', controller) }

    it 'delegates to the source named by params[:subauthority]' do
      expect(results).to contain_exactly(a_hash_including(id: '7', label: 'Ada Lovelace', value: '7'))
    end

    context 'when the source is unregistered' do
      let(:params) { ActionController::Parameters.new(q: 'Ada Byron', subauthority: 'nope') }

      it 'returns an empty list' do
        expect(results).to eq([])
      end
    end

    context 'when the source declares no similar proc' do
      before do
        Hyrax::CompoundLinkedRecordResolver.register(
          :searchonly, finder: ->(_id) {}, label: ->(_r) {}, path: ->(_r) {}, search: ->(_q) { [] }
        )
      end

      after { Hyrax::CompoundLinkedRecordResolver.registry.delete(:searchonly) }

      let(:params) { ActionController::Parameters.new(q: 'Ada Byron', subauthority: 'searchonly') }

      it 'returns an empty list' do
        expect(results).to eq([])
      end
    end

    context 'when no source (subauthority) is given' do
      let(:params) { ActionController::Parameters.new(q: 'Ada Byron') }

      it 'returns an empty list' do
        expect(results).to eq([])
      end
    end
  end
end
