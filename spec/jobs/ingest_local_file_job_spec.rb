RSpec.describe IngestLocalFileJob do
  let(:user) { create(:user) }

  let(:file_set) { FileSet.new }
  let(:actor) { double }

  before do
    allow(Hyrax::Actors::FileSetActor).to receive(:new).with(file_set, user).and_return(actor)
  end

  it 'has attached a file' do
    expect(FileUtils).not_to receive(:rm)
    expect(actor).to receive(:create_content).and_return(true)
    described_class.perform_now(file_set, File.join(fixture_path, 'world.png'), user)
  end
end
