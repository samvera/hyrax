describe Sufia::ActorFactory, :no_clean do
  let(:work) { GenericWork.new }
  let(:user) { double }

  describe '.stack_actors' do
    subject { described_class.stack_actors(work) }
    it do
      is_expected.to eq [Sufia::CreateWithRemoteFilesActor,
                         Sufia::CreateWithFilesActor,
                         CurationConcerns::Actors::AddToCollectionActor,
                         CurationConcerns::Actors::AddToWorkActor,
                         CurationConcerns::Actors::AssignRepresentativeActor,
                         CurationConcerns::Actors::AttachFilesActor,
                         CurationConcerns::Actors::ApplyOrderActor,
                         CurationConcerns::Actors::InterpretVisibilityActor,
                         Sufia::GrantEditToDepositorActor,
                         CurationConcerns::Actors::InitializeWorkflowActor,
                         Sufia::ApplyPermissionTemplateActor,
                         CurationConcerns::Actors::GenericWorkActor]
    end
  end

  describe '.build' do
    subject { described_class.build(work, user) }
    it "has the correct stack frames" do
      expect(subject.more_actors).to eq [
        Sufia::CreateWithFilesActor,
        CurationConcerns::Actors::AddToCollectionActor,
        CurationConcerns::Actors::AddToWorkActor,
        CurationConcerns::Actors::AssignRepresentativeActor,
        CurationConcerns::Actors::AttachFilesActor,
        CurationConcerns::Actors::ApplyOrderActor,
        CurationConcerns::Actors::InterpretVisibilityActor,
        Sufia::GrantEditToDepositorActor,
        CurationConcerns::Actors::InitializeWorkflowActor,
        Sufia::ApplyPermissionTemplateActor,
        CurationConcerns::Actors::GenericWorkActor
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
