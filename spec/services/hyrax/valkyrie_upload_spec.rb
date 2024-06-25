# frozen_string_literal: true

require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::ValkyrieUpload do
  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
  let(:file) { File.open('spec/fixtures/image.png') }
  let(:filename) { File.basename(file.path).to_s }
  let(:user) { create(:user) }

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
        filename: filename,
        file_set: file_set,
        io: file
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
        filename: filename,
        file_set: file_set,
        io: file,
        user: user
      )

      resource = Hyrax.query_service.find_by(id: file_set.id)

      expect(Hyrax.custom_queries.find_original_file(file_set: resource))
        .to be_a Hyrax::FileMetadata
    end

    it 'publishes events' do
      described_class.file(
        filename: filename,
        file_set: file_set,
        io: file,
        user: user
      )
      payload = listener.file_uploaded.map(&:payload)
      expect(payload.first[:metadata].id).to be_an_instance_of(Valkyrie::ID)
      expect(payload.first[:metadata].original_filename).to eq(filename)

      payload = listener.file_metadata_updated.map(&:payload)
      expect(payload.first[:metadata].id).to be_an_instance_of(Valkyrie::ID)
      expect(payload.first[:metadata].original_filename).to eq(filename)
      expect(payload.first[:user]).to eq(user)

      expect(listener.object_membership_updated.map(&:payload))
        .to contain_exactly(match(object: file_set,
                                  user: user))
    end
  end
end
