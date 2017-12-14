RSpec.describe CharacterizeJob do
  include ActionDispatch::TestProcess

  describe ".perform" do
    let(:char) { instance_double(Valkyrie::FileCharacterizationService) }
    let(:user) { create(:user) }
    let(:file_set) do
      create_for_repository(:file_set,
                            user: user,
                            content: file)
    end
    let(:file) { fixture_file_upload('/world.png', 'image/png') }
    let(:file_id) { file_set.original_file.id }

    before do
      allow(Valkyrie::FileCharacterizationService).to receive(:for).and_return(char)
      allow(char).to receive(:characterize)
    end

    it "invokes Valkyrie::FileCharacterizationService" do
      described_class.perform_now(file_set.id)
      # because once in the factory
      expect(char).to have_received(:characterize).twice
    end
  end
end
