require 'spec_helper'

describe CurationConcerns::Actors::ApplyOrderActor do
  describe '#update' do
    let(:curation_concern) { create(:work_with_two_children, user: user) }

    let(:user) { create(:admin) }

    subject do
      CurationConcerns::Actors::ActorStack.new(curation_concern,
                                               user,
                                               [described_class,
                                                CurationConcerns::Actors::GenericWorkActor])
    end

    context 'with ordered_member_ids that are already associated with the parent' do
      let(:attributes) { { ordered_member_ids: ["Blah"] } }
      let(:root_actor) { double }
      before do
        allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(root_actor)
        allow(root_actor).to receive(:update).with({}).and_return(true)
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
      end
      it "attaches the parent" do
        expect(subject.update(attributes)).to be true
      end
    end
  end

  describe '#update' do
    let(:user) { create(:admin) }
    let(:curation_concern) { create(:work_with_one_child, user: user) }
    let(:child) { GenericWork.new("Blah3") }

    subject do
      CurationConcerns::Actors::ActorStack.new(curation_concern,
                                               user,
                                               [described_class,
                                                CurationConcerns::Actors::GenericWorkActor])
    end

    context 'with ordered_members_ids that arent associated with the curation concern yet.' do
      let(:attributes) { { ordered_member_ids: ["Blah3"] } }
      let(:root_actor) { double }
      before do
        allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(root_actor)
        allow(root_actor).to receive(:update).with({}).and_return(true)
        child.title = ["Generic Title"]
        child.apply_depositor_metadata(user.user_key)
        child.save!
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
      end
      it "attaches the parent" do
        expect(subject.update(attributes)).to be true
      end
    end
  end
end
