require 'spec_helper'

RSpec.describe Hyrax::Actors::AttachMembersActor do
  let(:create_actor) do
    double('create actor', create: true,
                           curation_concern: work,
                           update: true,
                           user: depositor)
  end
  let(:actor) do
    Hyrax::Actors::ActorStack.new(work, depositor, [described_class])
  end
  let(:depositor) { create(:user) }
  let(:work) { create(:work) }
  let(:attributes) { { work_members_attributes: { '0' => { id: id } } } }

  describe "#update" do
    subject { actor.update(attributes) }
    before do
      work.ordered_members << existing_child_work
    end
    let(:existing_child_work) { create(:work) }
    let(:id) { existing_child_work.id }

    context "without useful attributes" do
      let(:attributes) { {} }
      it { is_expected.to be true }
    end

    context "when the id already exists in the members" do
      it "does nothing" do
        expect { subject }.not_to change { work.ordered_members.to_a }
      end

      context "and the _destroy flag is set" do
        let(:attributes) { { work_members_attributes: { '0' => { id: id, _destroy: 'true' } } } }

        it "removes from the member and the ordered members" do
          expect { subject }.to change { work.ordered_members.to_a }
          expect(work.ordered_member_ids).not_to include(existing_child_work.id)
          expect(work.member_ids).not_to include(existing_child_work.id)
        end
      end
    end

    context "when the id does not exist in the members" do
      let(:another_work) { create(:work) }
      let(:id) { another_work.id }
      context "and I can edit that object" do
        let(:ability) { instance_double(Ability) }
        before do
          allow(Ability).to receive(:new).and_return(ability)
          allow(ability).to receive(:can?).with(:edit, GenericWork).and_return(true)
        end
        it "is added to the ordered members" do
          expect { subject }.to change { work.ordered_members.to_a }
          expect(work.ordered_member_ids).to include(existing_child_work.id, another_work.id)
        end
      end

      context "and I can not edit that object" do
        it "does nothing" do
          expect { subject }.not_to change { work.ordered_members.to_a }
        end
      end
    end
  end
end
