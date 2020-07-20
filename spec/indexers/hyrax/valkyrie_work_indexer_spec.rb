# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::ValkyrieWorkIndexer do
  let(:indexer_class) { described_class }

  it_behaves_like 'a Hyrax::Resource indexer'
  it_behaves_like 'a Core metadata indexer'
  it_behaves_like 'a permission indexer'
  it_behaves_like 'a visibility indexer'

  context 'when extending with basic metadata' do
    let(:indexer_class) do
      Class.new(described_class) do
        include Hyrax::Indexer(:basic_metadata)
      end
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
          class WorkIndexer < Hyrax::ValkyrieWorkIndexer
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

    it_behaves_like 'a Hyrax::Resource indexer'
    it_behaves_like 'a Core metadata indexer'
    it_behaves_like 'a permission indexer'
    it_behaves_like 'a visibility indexer'
  end
end
