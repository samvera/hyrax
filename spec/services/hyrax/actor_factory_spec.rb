describe Hyrax::ActorFactory, :no_clean do
  let(:work) { GenericWork.new }
  let(:user) { double }

  describe '.stack_actors' do
    subject { described_class.stack_actors(work) }
    it do
      is_expected.to eq [Hyrax::CreateWithRemoteFilesActor,
                         Hyrax::CreateWithFilesActor,
                         Hyrax::Actors::AddAsMemberOfCollectionsActor,
                         Hyrax::Actors::AddToWorkActor,
                         Hyrax::Actors::AssignRepresentativeActor,
                         Hyrax::Actors::AttachFilesActor,
                         Hyrax::Actors::ApplyOrderActor,
                         Hyrax::Actors::InterpretVisibilityActor,
                         Hyrax::ApplyPermissionTemplateActor,
                         Hyrax::Actors::GenericWorkActor,
                         Hyrax::Actors::InitializeWorkflowActor]
    end
  end

  describe '.build' do
    subject { described_class.build(work, user) }
    it "has the correct stack frames" do
      expect(subject.more_actors).to eq [
        Hyrax::CreateWithFilesActor,
        Hyrax::Actors::AddAsMemberOfCollectionsActor,
        Hyrax::Actors::AddToWorkActor,
        Hyrax::Actors::AssignRepresentativeActor,
        Hyrax::Actors::AttachFilesActor,
        Hyrax::Actors::ApplyOrderActor,
        Hyrax::Actors::InterpretVisibilityActor,
        Hyrax::ApplyPermissionTemplateActor,
        Hyrax::Actors::GenericWorkActor,
        Hyrax::Actors::InitializeWorkflowActor
      ]
      expect(subject.first_actor_class).to eq Hyrax::CreateWithRemoteFilesActor
    end
  end

  describe 'Hyrax::CurationConcern.actor' do
    it "calls the Hyrax::ActorFactory" do
      expect(described_class).to receive(:build)
      Hyrax::CurationConcern.actor(work, user)
    end
  end
end
