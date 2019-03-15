# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::IdConverterService do
  let(:collection1) { create(:public_collection_lw, id: 'col1', title: ['Collection 1']) }
  let(:work1)       { create(:work, id: 'wk1', title: ['Work 1']) }
  let(:collection_resource1) { Wings::ModelTransformer.new(pcdm_object: collection1).build }
  let(:work_resource1) { Wings::ModelTransformer.new(pcdm_object: work1).build }
  let(:active_fedora_ids) { [collection1.id, work1.id] }
  let(:resource_ids) { [collection_resource1.id, work_resource1.id] }

  describe '#convert_to_active_fedora_ids' do
    it 'returns active fedora ids' do
      expect(described_class.convert_to_active_fedora_ids(resource_ids)).to match_array active_fedora_ids
    end
  end

  describe '#convert_to_valkyrie_resource_ids' do
    it 'returns valkyrie resource ids' do
      expect(described_class.convert_to_valkyrie_resource_ids(active_fedora_ids)).to match_array resource_ids
    end
  end
end
