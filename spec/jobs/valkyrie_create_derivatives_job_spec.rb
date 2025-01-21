# frozen_string_literal: true

require 'hyrax/specs/spy_listener'

RSpec.describe ValkyrieCreateDerivativesJob, perform_enqueued: true do
  # Create a work with two files, the first will be the work's thumbnail
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_file_sets, :with_thumbnail) }
  let(:upload_0) { FactoryBot.create(:uploaded_file, file_set_uri: file_sets[0].id, file: File.open('spec/fixtures/image.png')) }
  let(:upload_1) { FactoryBot.create(:uploaded_file, file_set_uri: file_sets[1].id, file: File.open('spec/fixtures/world.png')) }
  let(:file_id_0) { file_sets[0].original_file_id }
  let(:file_id_1) { file_sets[1].original_file_id }

  let(:characterizer) { double(characterize: fits_response) }
  let(:fits_response) { IO.read('spec/fixtures/png_fits.xml') }

  let(:derivatives_service) { instance_double("Hyrax::FileSetDerivativeService") }

  def file_sets
    Hyrax.custom_queries.find_child_file_sets(resource: work).to_a
  end

  before do
    # stub out characterization to avoid system calls. It's important some
    # amount of characterization happens so listeners fire.
    allow(Hydra::FileCharacterization).to receive(:characterize).and_return(fits_response)

    # This job depends on routes existing for the work. SimpleWork doesn't here, so skip it.
    allow(ContentUpdateEventJob).to receive(:perform_later)

    # Using ValkyrieIngestJob here is slow and runs the job this spec is supposed to test.
    # It should instead be handled by factories once real files can be attached
    # in the Hyrax::Work and Hyrax::FileSet factories.
    ValkyrieIngestJob.perform_now(upload_0)
    ValkyrieIngestJob.perform_now(upload_1)
  end

  describe '.perform_now' do
    context 'with files including the work thumbnail' do
      before do
        allow(Hyrax::DerivativeService).to receive(:for).and_return derivatives_service
        allow(Hyrax.index_adapter).to receive(:save).and_call_original
      end

      it 'creates derivatives and reindexes the work once' do
        expect(derivatives_service).to receive(:create_derivatives).twice
        expect(Hyrax.index_adapter).to receive(:save).with(resource: work).once
        described_class.perform_now(file_sets[1].id, file_id_1)
        described_class.perform_now(file_sets[0].id, file_id_0)
      end
    end
  end
end
