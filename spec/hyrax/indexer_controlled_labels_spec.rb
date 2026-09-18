# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::Indexer, '.Indexer controlled vocabulary labels' do
  subject(:document) { indexer_class.new(resource: work).to_solr }

  let(:work) { FactoryBot.build(:hyrax_work, title: ['A Title']) }

  let(:index_loader) do
    instance_double(Hyrax::SimpleSchemaLoader,
                    index_rules_for: index_rules,
                    authority_rules_for: authority_rules)
  end

  let(:index_rules)     { { title_tesim: :title, title_sim: :title } }
  let(:authority_rules) { {} }

  let(:indexer_class) do
    loader = index_loader
    Class.new(Hyrax::ValkyrieIndexer) do
      include Hyrax::Indexer(:core_metadata, index_loader: loader)
    end
  end

  context 'with no label service registered' do
    let(:authority_rules) { { title: 'title_authority' } }

    it 'indexes the stored ids and no label fields' do
      expect(document).to include(title_tesim: ['A Title'])
      expect(document.keys.grep(/_label_/)).to be_empty
    end
  end

  context 'with a label service that resolves the authority' do
    let(:authority_rules) { { title: 'title_authority' } }

    let(:label_service) do
      Class.new(Hyrax::ControlledVocabularyLabelService) do
        def resolvable?(source)
          source == 'title_authority'
        end

        def labels_for(_source, values)
          Array.wrap(values).map { |value| value == 'A Title' ? 'Resolved Label' : value }
        end
      end.new
    end

    before { allow(Hyrax.config).to receive(:controlled_vocabulary_label_service).and_return(label_service) }

    it 'writes the labels beside the untouched ids' do
      expect(document).to include(title_tesim: ['A Title'],
                                  title_label_tesim: ['Resolved Label'])
    end

    it 'keeps the label suffix last so the solr dynamic field matches' do
      expect(document).to have_key(:title_label_sim)
      expect(document).not_to have_key(:title_sim_label)
    end

    context 'and a property the service cannot resolve' do
      let(:authority_rules) { { title: 'unknown_authority' } }

      it 'indexes no label field for it' do
        expect(document.keys.grep(/_label_/)).to be_empty
      end
    end

    context 'and an uncontrolled property' do
      let(:authority_rules) { {} }

      it 'is left unchanged' do
        expect(document).to include(title_tesim: ['A Title'])
        expect(document.keys.grep(/_label_/)).to be_empty
      end
    end

    context 'with a multi-valued property only partly resolvable' do
      let(:work) { FactoryBot.build(:hyrax_work, title: ['A Title', 'Opaque', 'A Title']) }

      it 'keeps the labels positionally aligned with the values' do
        expect(document[:title_label_tesim]).to eq(['Resolved Label', 'Opaque', 'Resolved Label'])
      end
    end
  end

  context 'with two attributes citing the same authority' do
    let(:index_rules)     { { title_tesim: :title, title_sim: :title, creator_tesim: :creator } }
    let(:authority_rules) { { title: 'shared_authority', creator: 'shared_authority' } }
    let(:work)            { FactoryBot.build(:hyrax_work, title: ['A Title'], creator: ['A Creator']) }

    let(:label_service) do
      Class.new(Hyrax::ControlledVocabularyLabelService) do
        def resolvable?(_source)
          true
        end

        def labels_for(_source, values)
          Array.wrap(values).map { |value| "Label for #{value}" }
        end
      end.new
    end

    before { allow(Hyrax.config).to receive(:controlled_vocabulary_label_service).and_return(label_service) }

    it 'resolves each attribute against its own values' do
      expect(document[:title_label_tesim]).to eq(['Label for A Title'])
      expect(document[:creator_label_tesim]).to eq(['Label for A Creator'])
    end
  end

  context 'with a property carrying several index keys' do
    let(:index_rules)     { { title_tesim: :title, title_sim: :title } }
    let(:authority_rules) { { title: 'title_authority' } }

    let(:label_service) do
      Class.new(Hyrax::ControlledVocabularyLabelService) do
        def resolvable?(_source)
          true
        end

        def labels_for(_source, values)
          Array.wrap(values)
        end
      end.new
    end

    before do
      allow(Hyrax.config).to receive(:controlled_vocabulary_label_service).and_return(label_service)
      allow(label_service).to receive(:resolvable?).and_call_original
      allow(label_service).to receive(:labels_for).and_call_original
    end

    it 'asks the service once for the attribute, not once per index key' do
      document

      expect(label_service).to have_received(:labels_for).once
      expect(label_service).to have_received(:resolvable?).once
    end
  end

  context 'when the label service raises' do
    let(:authority_rules) { { title: 'title_authority' } }

    let(:label_service) do
      Class.new(Hyrax::ControlledVocabularyLabelService) do
        def resolvable?(_source)
          raise 'vocabulary backend is down'
        end
      end.new
    end

    before { allow(Hyrax.config).to receive(:controlled_vocabulary_label_service).and_return(label_service) }

    it 'still indexes the ids rather than failing the run' do
      expect(document).to include(title_tesim: ['A Title'])
    end
  end
end
