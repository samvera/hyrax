# frozen_string_literal: true

RSpec.describe Hyrax::S3Migration do
  describe '.file_set_class' do
    it 'is the Valkyrie file set class Hyrax is configured with' do
      expect(described_class.file_set_class).to eq Hyrax.config.valkyrie_file_set_class
    end

    it 'follows a custom configured file set class' do
      custom = Class.new(Hyrax::FileSet)
      allow(Hyrax.config).to receive(:valkyrie_file_set_class).and_return(custom)

      expect(described_class.file_set_class).to eq custom
    end
  end

  describe '.scope' do
    after { described_class.scope_provider = nil }

    it 'is nil by default' do
      expect(described_class.scope).to be_nil
    end

    it 'comes from the configured provider' do
      described_class.scope_provider = -> { 'one.example.com' }

      expect(described_class.scope).to eq 'one.example.com'
    end

    it 'treats a blank label as no scope' do
      described_class.scope_provider = -> { '' }

      expect(described_class.scope).to be_nil
    end
  end
end
