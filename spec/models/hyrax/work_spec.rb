# frozen_string_literal: true

require 'spec_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe Hyrax::Work do
  subject(:work) { described_class.new }

  it_behaves_like 'a Hyrax::Work'

  describe '#human_readable_type' do
    it 'has a human readable type' do
      expect(work.human_readable_type).to eq 'Work'
    end
  end

  describe '#state' do
    it 'is active by default' do
      expect(work.state).to eq Hyrax::ResourceStatus::ACTIVE
    end
  end

  it 'can be changed in after_create' do
    work = FactoryBot.valkyrie_create(:monograph_with_aggressive_title_setting)
    expect(work.title).to contain_exactly 'FORCED TITLE'
  end

  it 'matches attributes of reloaded work' do
    work = FactoryBot.valkyrie_create(:monograph_with_aggressive_title_setting)

    expect(work.attributes).to eq(Hyrax.query_service.find_by(id: work.id).attributes)
  end
end
