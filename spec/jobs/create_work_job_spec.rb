RSpec.describe CreateWorkJob do
  let(:user) { create(:user) }
  let(:log) do
    Hyrax::Operation.create!(user: user,
                             operation_type: "Create Work")
  end

  describe "#perform", perform_enqueued: [described_class] do
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
    let(:errors) { double(full_messages: ["It's broke!"]) }
    let(:work) { double(errors: errors) }
    let(:actor) { double(curation_concern: work) }

    subject do
      described_class.perform_later(user,
                                    'GenericWork',
                                    metadata,
                                    log)
    end

    before do
      allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
      allow(GenericWork).to receive(:new).and_return(work)
    end

    context "when the update is successful" do
      it "logs the success" do
        expect(actor).to receive(:create).with(Hyrax::Actors::Environment) do |env|
          expect(env.attributes).to eq("keyword" => [],
                                       "title" => ['File One'],
                                       "resource_type" => ["Article"],
                                       "permissions_attributes" =>
                                                 [{ "type" => "group", "name" => "public", "access" => "read" }],
                                       "visibility" => "open",
                                       "uploaded_files" => [upload1.id])
        end.and_return(true)
        subject
        expect(log.reload.status).to eq 'success'
      end
    end

    context "when the actor does not create the work" do
      it "logs the failure" do
        expect(actor).to receive(:create).and_return(false)
        subject
        expect(log.reload.status).to eq 'failure'
        expect(log.message).to eq "It's broke!"
      end
    end
  end
end
