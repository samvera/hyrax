describe Sufia::ActorFactory, :no_clean do
  let(:work) { GenericWork.new }
  let(:user) { double }

  describe '.stack_actors' do
    subject { described_class.stack_actors(work) }
    it do
      is_expected.to eq [Sufia::CreateWithRemoteFilesActor,
                         Sufia::CreateWithFilesActor,
                         Sufia::Actors::AddToCollectionActor,
                         Sufia::Actors::AddToWorkActor,
                         Sufia::Actors::AssignRepresentativeActor,
                         Sufia::Actors::AttachFilesActor,
                         Sufia::Actors::ApplyOrderActor,
                         Sufia::Actors::InterpretVisibilityActor,
                         Sufia::ApplyPermissionTemplateActor,
                         Sufia::Actors::GenericWorkActor,
                         Sufia::Actors::InitializeWorkflowActor]
    end
  end

  describe '.build' do
    subject { described_class.build(work, user) }
    it "has the correct stack frames" do
      expect(subject.more_actors).to eq [
        Sufia::CreateWithFilesActor,
        Sufia::Actors::AddToCollectionActor,
        Sufia::Actors::AddToWorkActor,
        Sufia::Actors::AssignRepresentativeActor,
        Sufia::Actors::AttachFilesActor,
        Sufia::Actors::ApplyOrderActor,
        Sufia::Actors::InterpretVisibilityActor,
        Sufia::ApplyPermissionTemplateActor,
        Sufia::Actors::GenericWorkActor,
        Sufia::Actors::InitializeWorkflowActor
      ]
      expect(subject.first_actor_class).to eq Sufia::CreateWithRemoteFilesActor
    end
  end

  describe 'CurationConcerns::CurationConcern.actor' do
    it "calls the Sufia::ActorFactory" do
      expect(described_class).to receive(:build)
      CurationConcerns::CurationConcern.actor(work, user)
    end
  end
end
