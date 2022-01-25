# frozen_string_literal: true
RSpec.describe ValkyrieIngestJob do
  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
  let(:upload) { FactoryBot.create(:uploaded_file, file_set_uri: file_set.id) }

  before do
    # stub out characterization to avoid system calls
    characterize = double(run: true)
    allow(Hyrax.config)
      .to receive(:characterization_service)
      .and_return(characterize)
  end

  describe '.perform_now' do
    it 'adds an original_file file to the file_set' do
      described_class.perform_now(upload)

      expect(Hyrax.query_service.find_by(id: file_set.id))
        .to have_attached_files(be_original_file)
    end

    context 'with no file_set_uri' do
      let(:upload) { FactoryBot.create(:uploaded_file) }

      it 'raises an error indicating a missing object' do
        expect { described_class.perform_now(upload) }
          .to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end
end
