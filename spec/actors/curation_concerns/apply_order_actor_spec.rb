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
      let(:attributes) { { ordered_member_ids: ["BlahBlah1"] } }
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
    let(:child) { GenericWork.new(id: "blahblah3") }

    subject do
      CurationConcerns::Actors::ActorStack.new(curation_concern,
                                               user,
                                               [described_class,
                                                CurationConcerns::Actors::GenericWorkActor])
    end

    context 'with ordered_members_ids that arent associated with the curation concern yet.' do
      let(:attributes) { { ordered_member_ids: [child.id] } }
      let(:root_actor) { double }
      before do
        allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(root_actor)
        allow(root_actor).to receive(:update).with({}).and_return(true)
        # TODO: This can be moved into the Factory
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

    context 'without an ordered_member_id that was associated with the curation concern' do
      let(:curation_concern) { create(:work_with_two_children, user: user) }
      let(:attributes) { { ordered_member_ids: ["BlahBlah2"] } }
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
      it "removes the first child" do
        expect(subject.update(attributes)).to be true
        expect(curation_concern.members.size).to eq(1)
        expect(curation_concern.ordered_member_ids.size).to eq(1)
      end
    end

    context 'with ordered_member_ids that include a work owned by a different user' do
      # set user not a non-admin for this test to ensure the actor disallows adding the child
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let(:child) { create(:generic_work, user: other_user) }
      let(:attributes) { { ordered_member_ids: [child.id] } }
      let(:root_actor) { double }

      before do
        allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(root_actor)
        allow(root_actor).to receive(:update).with({}).and_return(true)
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
      end

      it "does not attach the work" do
        expect(subject.update(attributes)).to be false
      end
    end
  end
end
