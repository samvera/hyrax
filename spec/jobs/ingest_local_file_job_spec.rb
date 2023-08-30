# frozen_string_literal: true

RSpec.describe IngestLocalFileJob, :active_fedora do
  let(:user) { create(:user) }
  let(:path) { File.join(fixture_path, 'world.png') }
  let(:file_set) { FileSet.new }

  it 'has attached a file' do
    expect(FileUtils).not_to receive(:rm)
    expect(Hyrax.config.callback).to receive(:run).with(:after_import_local_file_success, file_set, user, path, warn: false).and_return(true)
    described_class.perform_now(file_set, path, user)
  end

  context 'when an error is encountered when trying to save the file to disk' do
    let(:actor) { double }
    let(:callback) do
      instance_double(Hyrax::Callbacks::Registry)
    end
    let(:config) do
      instance_double(Hyrax::Configuration)
    end

    before do
      allow(Hyrax::Actors::FileSetActor).to receive(:new).with(file_set, user).and_return(actor)
      allow(callback).to receive(:run)
      allow(config).to receive(:callback).and_return(callback)
      allow(Hyrax).to receive(:config).and_return(config)
      allow(actor).to receive(:create_content).and_raise(SystemCallError, "example file system error")
      described_class.perform_now(file_set, path, user)
    end

    it "invokes the file failure callback" do
      expect(callback).to have_received(:run).with(:after_import_local_file_failure, file_set, user, path, warn: false)
    end
  end
end
