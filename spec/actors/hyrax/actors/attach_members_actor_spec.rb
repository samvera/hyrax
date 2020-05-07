RSpec.describe Hyrax::Actors::AttachMembersActor do
  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { create(:user) }
  let(:work) { create(:work) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  describe "#update" do
    subject { middleware.update(env) }

    before do
      work.ordered_members << existing_child_work
    end
    let(:existing_child_work) { create(:work) }

    context "without useful attributes" do
      let(:attributes) { {} }

      it { is_expected.to be true }
    end

    context "when the id already exists in the members" do
      let(:attributes) { HashWithIndifferentAccess.new(work_members_attributes: { '0' => { id: existing_child_work.id } }) }

      it "does nothing" do
        expect { subject }.not_to change { work.ordered_members.to_a }
      end

      context "and the _destroy flag is set" do
        let(:attributes) { HashWithIndifferentAccess.new(work_members_attributes: { '0' => { id: existing_child_work.id, _destroy: 'true' } }) }

        it "removes from the member and the ordered members" do
          expect { subject }.to change { work.ordered_members.to_a }
          expect(work.ordered_member_ids).not_to include(existing_child_work.id)
          expect(work.member_ids).not_to include(existing_child_work.id)
        end
      end
    end

    context "when working through Rails nested attribute scenarios" do
      before do
        allow(ability).to receive(:can?).with(:edit, GenericWork).and_return(true)
        work.ordered_members << work_to_remove
      end

      let(:work_to_remove) { create(:work, title: ['Already Member and Remove']) }
      let(:work_to_skip) { create(:work, title: ['Not a Member']) }
      let(:work_to_add) { create(:work, title: ['Not a Member but want to add']) }

      let(:attributes) do
        HashWithIndifferentAccess.new(
          work_members_attributes: {
            '0' => { id: work_to_remove.id, _destroy: 'true' }, # colleciton is a member and we're removing it
            '1' => { id: work_to_skip.id, _destroy: 'true' }, # colleciton is a NOT member and is marked for deletion; This is a UI introduced option
            '2' => { id: existing_child_work.id },
            '3' => { id: work_to_add.id }
          }
        )
      end

      it "handles destroy/non-destroy and keep/add behaviors" do
        expect { subject }.to change { work.ordered_members.to_a }
        expect(work.ordered_member_ids).to match_array [existing_child_work.id, work_to_add.id]
        expect(work.member_ids).to match_array [existing_child_work.id, work_to_add.id]
      end
    end

    context "when the id does not exist in the members" do
      let(:another_work) { create(:work) }
      let(:attributes) { HashWithIndifferentAccess.new(work_members_attributes: { '0' => { id: another_work.id } }) }

      context "and I can edit that object" do
        before do
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
