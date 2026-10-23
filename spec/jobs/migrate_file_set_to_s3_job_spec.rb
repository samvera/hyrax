# frozen_string_literal: true

RSpec.describe MigrateFileSetToS3Job do
  let(:file_set) { double('file_set') }
  let(:original) { double('original') }
  let(:migrator) { instance_double(Hyrax::S3Migration::FileMigrator, call: result) }
  let(:result) { Hyrax::S3Migration::FileMigrator::Result.new(status: :migrated) }

  before do
    allow(Hyrax.query_service).to receive(:find_by).with(id: 'fs1').and_return(file_set)
    allow(Hyrax.custom_queries).to receive(:find_original_file).with(file_set:).and_return(original)
    allow(Hyrax::S3Migration::FileMigrator).to receive(:new).and_return(migrator)
  end

  it 'runs the migrator for the file set and returns its result' do
    expect(described_class.perform_now('fs1')).to eq result
    expect(Hyrax::S3Migration::FileMigrator).to have_received(:new).with(file_set:, original:, dry_run: false)
  end

  it 'passes dry_run through' do
    described_class.perform_now('fs1', dry_run: true)

    expect(Hyrax::S3Migration::FileMigrator).to have_received(:new).with(file_set:, original:, dry_run: true)
  end

  it 'does nothing when the file set has no original file' do
    allow(Hyrax.custom_queries).to receive(:find_original_file).with(file_set:).and_return(nil)

    expect(described_class.perform_now('fs1')).to be_nil
    expect(Hyrax::S3Migration::FileMigrator).not_to have_received(:new)
  end

  it 'skips file sets that no longer exist' do
    allow(Hyrax.query_service).to receive(:find_by).and_raise(Valkyrie::Persistence::ObjectNotFoundError)

    expect { described_class.perform_now('fs1') }.not_to raise_error
  end

  it 'lets unexpected errors raise so the job can retry' do
    allow(migrator).to receive(:call).and_raise(Aws::S3::Errors::ServiceError.new(nil, 'throttled'))

    expect { described_class.new.perform('fs1') }.to raise_error(Aws::S3::Errors::ServiceError)
  end

  it 'uses the configured queue' do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('S3_MIGRATION_QUEUE', 'default').and_return('s3_migration')

    expect(described_class.new.queue_name).to eq 's3_migration'
  end
end
