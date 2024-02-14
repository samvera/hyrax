# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Indexers::PcdmObjectIndexer do
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_work) }
  let(:indexer_class) { described_class }

  it_behaves_like 'a Work indexer'

  context 'when extending with basic metadata' do
    let(:indexer_class) do
      Class.new(described_class) do
        include Hyrax::Indexer(:basic_metadata)
      end
    end
    let(:resource) do
      Class.new(Hyrax::Work) do
        # Included to address a `ArgumentError: Class name cannot be
        # blank. You need to supply a name argument when anonymous
        # class given`"
        def self.model_name
          ActiveModel::Name.new(self, nil, "TemporaryResource")
        end
        include Hyrax::Schema(:basic_metadata)
      end.new
    end

    it_behaves_like 'a Basic metadata indexer'
  end

  context 'when extending with custom metadata' do
    before do
      module Hyrax::Test
        module Custom
          class Work < Hyrax::Work
            attribute :broader, Valkyrie::Types::Array.of(Valkyrie::Types::String)
          end

          class WorkIndexer < Hyrax::Indexers::PcdmObjectIndexer(Hyrax::Test::Custom::Work)
            def to_solr
              super.tap do |solr_doc|
                solr_doc['broader_ssim'] = resource.broader.first
              end
            end
          end
        end
      end
    end
    after { Hyrax::Test.send(:remove_const, :Custom) }

    let(:resource) { Hyrax.persister.save(resource: Hyrax::Test::Custom::Work.new(broader: ['term1', 'term2'])) }
    let(:indexer_class) { Hyrax::Test::Custom::WorkIndexer }

    it_behaves_like 'a Work indexer'
  end

  describe '#to_solr' do
    let(:service) { described_class.new(resource: work) }
    subject(:solr_document) { service.to_solr }

    let(:user) { create(:user) }
    let(:admin_set_title) { 'An Admin Set' }
    let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, title: [admin_set_title]) }
    let(:collection_title) { 'A Collection' }
    let(:col1) { FactoryBot.valkyrie_create(:hyrax_collection, title: [collection_title]) }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_works, member_of_collection_ids: [col1.id], admin_set_id: admin_set.id, depositor: user.email) }

    it 'includes attributes defined outside Hyrax::Schema include' do
      expect(solr_document.fetch('generic_type_si')).to eq 'Work'
      expect(solr_document.fetch('admin_set_sim')).to match_array [admin_set_title]
      expect(solr_document.fetch('admin_set_tesim')).to match_array [admin_set_title]
      expect(solr_document.fetch('admin_set_id_ssim')).to match_array [admin_set.id]
      expect(solr_document.fetch('isPartOf_ssim')).to match_array [admin_set.id]
      expect(solr_document.fetch('member_ids_ssim')).to match_array work.member_ids
      expect(solr_document.fetch('member_of_collection_ids_ssim')).to match_array [col1.id]
      expect(solr_document.fetch('depositor_ssim')).to match_array [user.email]
      expect(solr_document.fetch('depositor_tesim')).to match_array [user.email]
    end

    context 'when work is inactive' do
      before { allow(work).to receive(:state).and_return(Hyrax::ResourceStatus::INACTIVE) }
      it 'sets suppressed to true' do
        expect(solr_document.fetch('suppressed_bsi')).to be true
      end
    end

    context 'when work is active' do
      before { allow(work).to receive(:state).and_return(Hyrax::ResourceStatus::ACTIVE) }
      it 'sets suppressed to false' do
        expect(solr_document.fetch('suppressed_bsi')).to be false
      end
    end

    context 'when work is under embargo' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, embargo: embargo) }
      let(:embargo) { FactoryBot.valkyrie_create(:hyrax_embargo) }

      it 'indexes the embargo visibilities' do
        expect(service.to_solr)
          .to include('visibility_after_embargo_ssim' => embargo.visibility_after_embargo,
                      'visibility_during_embargo_ssim' => embargo.visibility_during_embargo)
      end

      it 'indexes the embargo release date' do
        expect(service.to_solr)
          .to include('embargo_release_date_dtsi' => embargo.embargo_release_date.to_datetime)
      end
    end

    context 'when work is under lease' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, lease: lease) }
      let(:lease) { FactoryBot.valkyrie_create(:hyrax_lease) }

      it 'indexes the lease visibilities' do
        expect(service.to_solr).to include('visibility_after_lease_ssim' => lease.visibility_after_lease,
                                           'visibility_during_lease_ssim' => lease.visibility_during_lease)
      end

      it 'indexes the lease expiration date' do
        expect(service.to_solr)
          .to include('lease_expiration_date_dtsi' => lease.lease_expiration_date.to_datetime)
      end
    end
  end
end
