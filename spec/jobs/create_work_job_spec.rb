RSpec.describe CreateWorkJob do
  let(:user) { create(:user) }
  let(:log) do
    Hyrax::Operation.create!(user: user,
                             operation_type: "Create Work")
  end

  describe "#perform" do
    let(:file1) { File.open(fixture_path + '/world.png') }
    let(:upload1) { Hyrax::UploadedFile.create(user: user, file: file1) }
    let(:metadata) do
      { keyword: [],
        "permissions_attributes" => [{ "type" => "group", "name" => "public", "access" => "read" }],
        "visibility" => 'open',
        uploaded_files: [upload1.id],
        title: ['File One'],
        resource_type: ['Article'] }
    end

    subject do
      described_class.perform_later(user,
                                    'GenericWork',
                                    metadata,
                                    log)
    end

    context 'when the update is successful' do
      it 'logs the success' do
        expect { subject }.to change { Hyrax::Queries.find_all_of_model(model: GenericWork).size }.by(1)
        expect(log.reload.status).to eq 'success'
      end
    end

    context 'when the actor does not create the work' do
      let(:change_set) { instance_double(GenericWorkChangeSet, validate: false, errors: errors) }
      let(:errors) { double(full_messages: ["It's broke!"]) }

      before do
        allow(GenericWorkChangeSet).to receive(:new).and_return(change_set)
      end

      it 'logs the failure' do
        subject
        expect(log.reload.status).to eq 'failure'
        expect(log.message).to eq "It's broke!"
      end
    end
  end
end
