# frozen_string_literal: true

RSpec.describe Hyrax::S3Migration::StorageReport do
  let(:original_use) { RDF::URI('http://pcdm.org/use#OriginalFile') }
  let(:thumbnail_use) { RDF::URI('http://pcdm.org/use#ThumbnailImage') }

  def file(use, identifier, size)
    double('file', pcdm_use: [use], file_identifier: Valkyrie::ID.new(identifier), recorded_size: [size])
  end

  it 'tallies files and bytes by use and storage scheme' do
    file_sets = [double('fs1'), double('fs2')]
    allow(Hyrax::S3Migration).to receive(:each_file_set) { |&block| file_sets.each(&block) }
    allow(Hyrax.custom_queries).to receive(:find_files).with(file_set: file_sets[0])
                                                       .and_return([file(original_use, 'disk:///a', 100), file(thumbnail_use, 'disk:///t', 5)])
    allow(Hyrax.custom_queries).to receive(:find_files).with(file_set: file_sets[1])
                                                       .and_return([file(original_use, 'shrine://x/y', 200), file(original_use, 'disk:///b', 50)])

    expect(described_class.call).to eq(
      %w[OriginalFile disk] => [2, 150],
      %w[OriginalFile shrine] => [1, 200],
      %w[ThumbnailImage disk] => [1, 5]
    )
  end

  it 'counts file sets whose file records are missing instead of failing' do
    file_sets = [double('good'), double('broken')]
    allow(Hyrax::S3Migration).to receive(:each_file_set) { |&block| file_sets.each(&block) }
    allow(Hyrax.custom_queries).to receive(:find_files).with(file_set: file_sets[0]).and_return([file(original_use, 'disk:///a', 10)])
    allow(Hyrax.custom_queries).to receive(:find_files).with(file_set: file_sets[1]).and_raise(Valkyrie::Persistence::ObjectNotFoundError)

    expect(described_class.call).to eq(%w[OriginalFile disk] => [1, 10], ['(file record missing)', '-'] => [1, 0])
  end

  it 'ticks the progress reporter once per file set' do
    file_sets = [double('fs1'), double('fs2'), double('fs3')]
    allow(Hyrax::S3Migration).to receive(:each_file_set) { |&block| file_sets.each(&block) }
    allow(Hyrax.custom_queries).to receive(:find_files).and_return([])
    progress = instance_double(Hyrax::S3Migration::Progress, tick: nil)

    described_class.call(progress:)

    expect(progress).to have_received(:tick).exactly(3).times
  end
end
