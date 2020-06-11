# frozen_string_literal: true
RSpec.describe Hyrax::DatabaseMigrator do
  describe '.copy' do
    let(:mock_migrator) { double }

    it 'creates an instance and calls #copy' do
      expect(described_class).to receive(:new).once.and_return(mock_migrator)
      expect(mock_migrator).to receive(:copy).once
      described_class.copy
    end
  end

  describe '#copy' do
    let(:migrations_count) { subject.send(:migrations).count }

    it 'uses #migration_template to copy all migrations to app' do
      expect(subject).to receive(:migration_template).exactly(migrations_count).times
      subject.copy
    end
  end
end
