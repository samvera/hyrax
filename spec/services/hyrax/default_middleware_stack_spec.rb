RSpec.describe Hyrax::DefaultMiddlewareStack do
  let(:work) { GenericWork.new }
  let(:user) { double(current_user: double) }

  describe '.build_stack' do
    subject { described_class.build_stack }

    it "has the correct stack frames" do
      expect(subject.middlewares).to eq [
        Hyrax::Actors::TransactionalRequest,
        Hyrax::Actors::OptimisticLockValidator,
        Hyrax::Actors::CreateWithRemoteFilesActor,
        Hyrax::Actors::CreateWithFilesActor,
        Hyrax::Actors::CollectionsMembershipActor,
        Hyrax::Actors::AddToWorkActor,
        Hyrax::Actors::AssignRepresentativeActor,
        Hyrax::Actors::AttachMembersActor,
        Hyrax::Actors::InterpretVisibilityActor,
        Hyrax::Actors::TransferRequestActor,
        Hyrax::Actors::DefaultAdminSetActor,
        Hyrax::Actors::ApplyPermissionTemplateActor,
        Hyrax::Actors::CleanupFileSetsActor,
        Hyrax::Actors::CleanupTrophiesActor,
        Hyrax::Actors::FeaturedWorkActor,
        Hyrax::Actors::ModelActor,
        Hyrax::Actors::InitializeWorkflowActor
      ]
    end
  end

  describe 'Hyrax::CurationConcern.actor' do
    it "calls the Hyrax::ActorFactory" do
      expect(Hyrax::CurationConcern.actor).to be_instance_of Hyrax::Actors::TransactionalRequest
    end
  end
end
