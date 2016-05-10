require 'spec_helper'

describe Sufia::ActorFactory do
  let(:work) { GenericWork.new }
  let(:user) { double }

  describe '.stack_actors' do
    subject { described_class.stack_actors(work) }
    it { is_expected.to eq [Sufia::CreateWithRemoteFilesActor,
                            Sufia::CreateWithFilesActor,
                            CurationConcerns::AddToCollectionActor,
                            CurationConcerns::AssignRepresentativeActor,
                            CurationConcerns::AttachFilesActor,
                            CurationConcerns::ApplyOrderActor,
                            CurationConcerns::InterpretVisibilityActor,
                            CurationConcerns::GenericWorkActor,
                            CurationConcerns::AssignIdentifierActor] }
  end

  describe '.build' do
    subject { described_class.build(work, user) }
    it "has the correct stack frames" do
      expect(subject.more_actors).to eq [
        Sufia::CreateWithFilesActor,
        CurationConcerns::AddToCollectionActor,
        CurationConcerns::AssignRepresentativeActor,
        CurationConcerns::AttachFilesActor,
        CurationConcerns::ApplyOrderActor,
        CurationConcerns::InterpretVisibilityActor,
        CurationConcerns::GenericWorkActor,
        CurationConcerns::AssignIdentifierActor
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
