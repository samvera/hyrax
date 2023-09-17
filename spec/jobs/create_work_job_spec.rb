# frozen_string_literal: true
RSpec.describe CreateWorkJob do
  let(:user) { FactoryBot.create(:user) }
  let(:log) do
    Hyrax::Operation.create!(user: user,
                             operation_type: "Create Work")
  end

  describe "#perform", perform_enqueued: [described_class] do
    let(:file1) { File.open(fixture_path + '/world.png') }
    let(:upload1) { Hyrax::UploadedFile.create(user: user, file: file1) }
    let(:metadata) do
      { keyword: [],
        permissions_attributes: [{ "type" => "group", "name" => "public", "access" => "read" }],
        visibility: 'open',
        uploaded_files: [upload1.id],
        title: ['File One'],
        creator: ['Last, First'],
        resource_type: ['Article'] }
    end
    let(:errors) { double(full_messages: ["It's broke!"]) }
    let(:work) { double(errors: errors) }
    let(:actor) { double(curation_concern: work) }

    context "with an ActiveFedora model", skip: !(GenericWork < ActiveFedora::Base) do
      before do
        allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
        allow(GenericWork).to receive(:new).and_return(work)
      end

      context "when the update is successful" do
        it "logs the success" do
          expect(actor).to receive(:create).with(Hyrax::Actors::Environment) do |env|
            expect(env.attributes).to eq("keyword" => [],
                                         "title" => ['File One'],
                                         "creator" => ['Last, First'],
                                         "resource_type" => ["Article"],
                                         "permissions_attributes" =>
                                                  [{ "type" => "group", "name" => "public", "access" => "read" }],
                                         "visibility" => "open",
                                         "uploaded_files" => [upload1.id])
          end.and_return(true)
          described_class.perform_later(user, 'GenericWork', metadata, log)
          expect(log.reload.status).to eq 'success'
        end
      end

      context "when the actor does not create the work" do
        it "logs the failure" do
          expect(actor).to receive(:create).and_return(false)
          described_class.perform_later(user, 'GenericWork', metadata, log)
          expect(log.reload.status).to eq 'failure'
          expect(log.message).to eq "It's broke!"
        end
      end
    end

    context "with a Valkyrie model", skip: GenericWork < ActiveFedora::Base do
      context "when there is a validation error" do
        let(:metadata) do
          { keyword: [],
            permissions_attributes: [{ "type" => "group", "name" => "public", "access" => "read" }],
            visibility: 'open',
            uploaded_files: [upload1.id],
            resource_type: ['Article'] }
        end

        it "logs the failure" do
          described_class.perform_later(user, 'GenericWork', metadata, log)
          expect(log.reload.status).to eq 'failure'
          expect(log.message).to eq "Title can't be blank Creator can't be blank"
        end
      end

      it "it creates a work and a file_set" do
        described_class.perform_later(user, 'GenericWork', metadata, log)
        work_id = Hyrax.custom_queries.find_ids_by_model(model: GenericWork).first
        work = Hyrax.query_service.find_by(id: work_id)
        expect(work.title).to eq ['File One']
        expect(work.creator).to eq ['Last, First']
        expect(work.depositor).to eq user.to_s
        expect(work.member_ids.count).to eq 1
        expect(log.reload.status).to eq 'success'
      end
    end
  end
end
