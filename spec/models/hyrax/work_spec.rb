# frozen_string_literal: true

require 'spec_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe Hyrax::Work do
  subject(:work) { described_class.new }

  it_behaves_like 'a Hyrax::Work'

  it 'can set and unset values' do
    work.title = ['moomin']
    id = Hyrax.persister.save(resource: work).id
    re = Hyrax.query_service.find_by(id: id)
    re.title = nil

    expect { Hyrax.persister.save(resource: re) }
      .to change { Hyrax.query_service.find_by(id: id).title }
      .from(contain_exactly('moomin'))
      .to be_empty
  end

  context 'when fields generated from schema' do
    let(:monograph) { FactoryBot.valkyrie_create(:monograph, title: 'A Monograph', creator: [""]) }
    it "removes blank strings from params before updating work metadata" do
      expect(monograph.title).to eq ["A Monograph"]
      expect(monograph.creator).to eq []
    end
  end

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
end
