# frozen_string_literal: true

RSpec.describe Hyrax::Actors::CreateWithFilesActor do
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:work) { create(:generic_work, user: user) }

  let(:create_actor) do
    double('create actor', create: true,
                           curation_concern: work,
                           update: true,
                           user: user)
  end
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:uploaded_file1) { Hyrax::UploadedFile.create(user: user) }
  let(:uploaded_file2) { Hyrax::UploadedFile.create(user: user) }
  let(:work) { create(:generic_work, user: user) }
  let(:uploaded_file_ids) { [uploaded_file1.id, uploaded_file2.id] }
  let(:attributes) { { uploaded_files: uploaded_file_ids } }

  [:create, :update].each do |mode|
    context "on #{mode}" do
      before do
        allow(terminator).to receive(mode).and_return(true)
      end
      context "when uploaded_file_ids include nil" do
        let(:uploaded_file_ids) { [nil, uploaded_file1.id, nil] }
        it "will discard those nil values when attempting to find the associated UploadedFile" do
          expect(AttachFilesToWorkJob).to receive(:perform_later)
          expect(Hyrax::UploadedFile).to receive(:find).with([uploaded_file1.id]).and_return([uploaded_file1])
          middleware.public_send(mode, env)
        end
      end

      context "when uploaded_file_ids belong to me" do
        it "attaches files" do
          expect(AttachFilesToWorkJob).to receive(:perform_later).with(GenericWork, [uploaded_file1, uploaded_file2])
          expect(middleware.public_send(mode, env)).to be true
        end
      end

      context "when uploaded_file_ids don't belong to me" do
        let(:uploaded_file2) { Hyrax::UploadedFile.create }
        it "doesn't attach files" do
          expect(AttachFilesToWorkJob).not_to receive(:perform_later)
          expect(middleware.public_send(mode, env)).to be false
        end
      end
    end
  end
end
