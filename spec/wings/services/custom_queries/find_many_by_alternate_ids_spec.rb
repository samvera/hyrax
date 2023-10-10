# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings_helper'
require 'wings/services/custom_queries/find_many_by_alternate_ids'

RSpec.describe Wings::CustomQueries::FindManyByAlternateIds, :active_fedora do
  let(:query_service) { Hyrax.query_service }

  let(:work1) { create(:public_work) }
  let(:work2) { create(:public_work) }
  let(:hyrax_ids_array) { [work1.id, work2.id] }
  let(:valk_ids_array) { [::Valkyrie::ID.new(work1.id), ::Valkyrie::ID.new(work2.id)] }
  let(:valk_id_work1) { ::Valkyrie::ID.new(work1.id).id }
  let(:valk_id_work2) { ::Valkyrie::ID.new(work2.id).id }
  let(:subject) { query_service.custom_queries.find_many_by_alternate_ids(alternate_ids: id_list, use_valkyrie: use_valkyrie_value) }

  describe '.find_many_by_alternate_ids' do
    context 'with Valkyrie::ID input' do
      let(:id_list) { valk_ids_array }
      let(:use_valkyrie_value) { false }

      it 'returns objects of requested type' do
        expect(subject.first.is_a?(ActiveFedora::Base)).to be true
        expect(subject.map(&:id)).to contain_exactly(work2.id, work1.id)
      end
    end

    context 'when use_valkyrie: true' do
      let(:use_valkyrie_value) { true }
      let(:id_list) { hyrax_ids_array }

      it 'returns Valkyrie::Resource objects' do
        expect(subject.first).to be_a(Valkyrie::Resource)
        expect(subject.map(&:alternate_ids).flatten.map(&:id)).to contain_exactly(valk_id_work2, valk_id_work1)
      end
    end

    context 'when use_valkyrie: false' do
      let(:use_valkyrie_value) { false }
      let(:id_list) { hyrax_ids_array }

      it 'returns ActiveFedora objects' do
        expect(subject.first.is_a?(ActiveFedora::Base)).to be true
        expect(subject.map(&:id)).to contain_exactly(work2.id, work1.id)
        expect { subject } .not_to raise_error
      end
    end

    context 'when list includes an invalid id' do
      let(:id_list) { [work1.id, work2.id, '1212121212'] }

      it 'raises an exception' do
        expect { subject } .to raise_error(NameError)
      end
    end
  end
end
