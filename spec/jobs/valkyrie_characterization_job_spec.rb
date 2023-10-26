# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ValkyrieCharacterizationJob, valkyrie_adapter: :test_adapter do
  context 'with a file' do
    let(:file_metadata) { FactoryBot.valkyrie_create(:hyrax_file_metadata) }
    let(:file) { double }

    before do
      allow(file_metadata).to receive(:file).and_return(file)
      allow(Hyrax.custom_queries).to receive(:find_file_metadata_by).with(id: file_metadata.id).and_return(file_metadata)
    end

    it 'calls the characterization service' do
      expect(Hyrax.config.characterization_service).to receive(:run).with(metadata: file_metadata, file: file, **Hyrax.config.characterization_options)
      described_class.perform_now(file_metadata.id)
    end
  end
end
