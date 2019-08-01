# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax::Matchers::MatchValkyrieIdsWithActiveFedoraIds do
  context 'when valkyrie ids and active fedora ids match' do
    let(:valkyrie_ids) { [Valkyrie::ID.new('id1'), Valkyrie::ID.new('id2')] }
    let(:af_ids) { ['id1', 'id2'] }

    it 'returns true' do
      expect(valkyrie_ids).to match_valkyrie_ids_with_active_fedora_ids(af_ids)
    end
  end

  context 'when valkyrie ids exist and active fedora id array is empty' do
    let(:valkyrie_ids) { [Valkyrie::ID.new('id1'), Valkyrie::ID.new('id2')] }
    let(:af_ids) { [] }

    it 'returns false' do
      expect(valkyrie_ids).not_to match_valkyrie_ids_with_active_fedora_ids(af_ids)
    end
  end

  context 'when valkyrie id array is empty and active fedora ids exist' do
    let(:valkyrie_ids) { [] }
    let(:af_ids) { ['id1', 'id2'] }

    it 'returns false' do
      expect(valkyrie_ids).not_to match_valkyrie_ids_with_active_fedora_ids(af_ids)
    end
  end

  context 'when valkyrie ids and active fedora ids DO NOT match' do
    let(:valkyrie_ids) { [Valkyrie::ID.new('id1'), Valkyrie::ID.new('id2')] }
    let(:af_ids) { ['id1', 'id3'] }

    it 'returns false' do
      expect(valkyrie_ids).not_to match_valkyrie_ids_with_active_fedora_ids(af_ids)
    end
  end
end
