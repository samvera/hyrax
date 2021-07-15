# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::ValkyrieAdministrativeSetIndexer do
  describe '#to_solr' do
    let(:service) { described_class.new(resource: admin_set) }
    subject(:solr_document) { service.to_solr }

    let(:user) { create(:user) }
    let(:admin_set_title) { 'An Admin Set' }
    let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, title: [admin_set_title]) }

    it 'includes default attributes ' do
      expect(solr_document.fetch('generic_type_si')).to eq 'Admin Set'
      expect(solr_document.fetch('title_tesim')).to eq ['An Admin Set']
    end
  end
end
