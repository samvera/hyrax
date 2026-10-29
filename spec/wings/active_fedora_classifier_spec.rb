# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings_helper'

RSpec.describe Wings::ActiveFedoraClassifier, :active_fedora do
  subject(:classifier) { described_class.new(model_name) }

  describe '#best_model' do
    context 'with a Wings file metadata model' do
      let(:model_name) { 'Wings(Hyrax::FileMetadata)' }

      # Simulate a fresh process, where no class has been built for
      # Hyrax::FileMetadata yet (e.g. a reindex run from a rake task).
      before { Wings::ActiveFedoraConverter.class_cache.delete(Hyrax::FileMetadata) }

      it 'resolves to a FileMetadataNode so its Solr fields survive a reindex' do
        expect(classifier.best_model).to be < Wings::FileMetadataNode
      end
    end

    context 'with another Wings resource model' do
      let(:model_name) { 'Wings(Hyrax::Work)' }

      it 'resolves to a DefaultWork' do
        expect(classifier.best_model).to be < Wings::ActiveFedoraConverter::DefaultWork
      end
    end
  end
end
