# frozen_string_literal: true

require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::ValkyrieUpload do
  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
  let(:upload) { FactoryBot.create(:uploaded_file, file_set_uri: file_set.id, file: File.open('spec/fixtures/image.png')) }

  let(:listener) { Hyrax::Specs::AppendingSpyListener.new }
  let(:characterizer) { double(characterize: fits_response) }
  let(:fits_response) { IO.read('spec/fixtures/png_fits.xml') }

  before do
    Hyrax.publisher.subscribe(listener)

    # stub out characterization to avoid system calls. It's important some
    # amount of characterization happens so listeners fire.
    allow(Hydra::FileCharacterization).to receive(:characterize).and_return(fits_response)
  end

  after { Hyrax.publisher.unsubscribe(listener) }

  describe '.file' do
    it 'adds an original_file file to the file_set' do
      described_class.file(
        filename: Rails.root.join('spec', 'fixtures', 'image.png'),
        file_set: file_set,
        io: upload.uploader.file.to_file
      )

      reloaded_file_set = Hyrax.query_service.find_by(id: file_set.id)
      expect(reloaded_file_set)
        .to have_attached_files(be_original_file)
      expect(reloaded_file_set.title).to eq ["image.png"]
      expect(reloaded_file_set.label).to eq "image.png"
      expect(reloaded_file_set.file_ids)
        .to contain_exactly(reloaded_file_set.original_file_id)
    end

    it 'makes original_file queryable by use' do
      described_class.file(
        filename: Rails.root.join('spec', 'fixtures', 'image.png'),
        file_set: file_set,
        io: upload.uploader.file.to_file,
        user: upload.user
      )

      resource = Hyrax.query_service.find_by(id: file_set.id)

      expect(Hyrax.custom_queries.find_original_file(file_set: resource))
        .to be_a Hyrax::FileMetadata
    end

    it 'publishes events' do
      described_class.file(
        filename: Rails.root.join('spec', 'fixtures', 'image.png'),
        file_set: file_set,
        io: upload.uploader.file.to_file,
        user: upload.user
      )
      expect(listener.object_file_uploaded.map(&:payload))
        .to contain_exactly(match(metadata: have_attributes(id: an_instance_of(Valkyrie::ID),
                                                            original_filename: upload.file.filename)))

      expect(listener.file_metadata_updated.map(&:payload))
        .to include(match(metadata: have_attributes(id: an_instance_of(Valkyrie::ID),
                                                    original_filename: upload.file.filename),
                          user: upload.user))

      expect(listener.object_membership_updated.map(&:payload))
        .to contain_exactly(match(object: file_set,
                                  user: upload.user))
    end
  end
end
