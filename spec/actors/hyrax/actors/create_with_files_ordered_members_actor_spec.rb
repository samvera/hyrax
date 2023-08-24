# frozen_string_literal: true
RSpec.describe Hyrax::Actors::CreateWithFilesOrderedMembersActor, :active_fedora do
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:work) { create(:generic_work, user: user) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:uploaded_file1) { create(:uploaded_file, user: user) }
  let(:uploaded_file2) { create(:uploaded_file, user: user) }
  let(:uploaded_file_ids) { [uploaded_file1.id, uploaded_file2.id] }
  let(:attributes) { { uploaded_files: uploaded_file_ids } }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  [:create, :update].each do |mode|
    context "on #{mode}" do
      before do
        allow(terminator).to receive(mode).and_return(true)
      end
      context "when uploaded_file" do
        it "invoke the job" do
          expect(AttachFilesToWorkWithOrderedMembersJob).to receive(:perform_later)
          middleware.public_send(mode, env)
        end
      end

      context "when no uploaded_file" do
        let(:uploaded_file_ids) { [] }

        it "doesn't invoke job" do
          expect(AttachFilesToWorkWithOrderedMembersJob).not_to receive(:perform_later)
          expect(middleware.public_send(mode, env)).to be true
        end
      end
    end
  end
end
