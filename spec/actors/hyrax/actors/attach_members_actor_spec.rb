# frozen_string_literal: true
RSpec.describe Hyrax::Actors::AttachMembersActor, :active_fedora do
  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { create(:user) }
  let(:work) { create(:work) }
  let(:attributes) { HashWithIndifferentAccess.new(work_members_attributes: { '0' => { id: existing_child_work.id } }) }
  let(:existing_child_work) { create(:work) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end

    stack.build(terminator)
  end

  describe "#update" do
    context 'when using an active_fedora work' do
      before { work.ordered_members << existing_child_work }

      context "without useful attributes" do
        let(:attributes) { {} }

        it { expect(middleware.update(env)).to be true }
      end

      context "when the id already exists in the members" do
        let(:attributes) { HashWithIndifferentAccess.new(work_members_attributes: { '0' => { id: existing_child_work.id } }) }

        it "does nothing" do
          expect { middleware.update(env) }.not_to change { env.curation_concern.ordered_members.to_a }
        end

        context "and the _destroy flag is set" do
          let(:attributes) { HashWithIndifferentAccess.new(work_members_attributes: { '0' => { id: existing_child_work.id, _destroy: 'true' } }) }

          it "removes from the member and the ordered members" do
            expect { middleware.update(env) }.to change { env.curation_concern.ordered_members.to_a }
            expect(env.curation_concern.ordered_member_ids).not_to include(existing_child_work.id)
            expect(env.curation_concern.member_ids).not_to include(existing_child_work.id)
          end
        end
      end

      context "when working through Rails nested attribute scenarios" do
        before do
          allow(ability).to receive(:can?).with(:edit, String).and_return(true)
          work.ordered_members << work_to_remove
        end

        let(:work_to_remove) { create(:work, title: ['Already Member and Remove']) }
        let(:work_to_skip) { create(:work, title: ['Not a Member']) }
        let(:work_to_add) { create(:work, title: ['Not a Member but want to add']) }

        let(:attributes) do
          HashWithIndifferentAccess.new(
            work_members_attributes: {
              '0' => { id: work_to_remove.id, _destroy: 'true' }, # colleciton is a member and we're removing it
              '1' => { id: work_to_skip.id, _destroy: 'true' }, # collection is a NOT member and is marked for deletion; This is a UI introduced option
              '2' => { id: existing_child_work.id },
              '3' => { id: work_to_add.id }
            }
          )
        end

        it "handles destroy/non-destroy and keep/add behaviors" do
          expect { middleware.update(env) }.to change { env.curation_concern.ordered_members.to_a }
          expect(env.curation_concern.ordered_member_ids).to match_array [existing_child_work.id, work_to_add.id]
          expect(env.curation_concern.member_ids).to match_array [existing_child_work.id, work_to_add.id]
        end
      end

      context "when the id does not exist in the members" do
        let(:another_work) { create(:work) }
        let(:attributes) { HashWithIndifferentAccess.new(work_members_attributes: { '0' => { id: another_work.id } }) }

        context "and I can edit that object" do
          before do
            allow(ability).to receive(:can?).with(:edit, String).and_return(true)
          end
          it "is added to the ordered members" do
            expect { middleware.update(env) }.to change { env.curation_concern.ordered_members.to_a }
            expect(env.curation_concern.ordered_member_ids).to include(existing_child_work.id, another_work.id)
          end
        end

        context "and I can not edit that object" do
          it "does nothing" do
            expect { middleware.update(env) }.not_to change { env.curation_concern.ordered_members.to_a }
          end
        end
      end
    end

    context 'when using a valkyrie resource' do
      let(:work) { create(:work).valkyrie_resource }

      before { work.member_ids << Valkyrie::ID.new(existing_child_work.id) }

      context "when the _destroy flag is set" do
        let(:attributes) { HashWithIndifferentAccess.new(work_members_attributes: { '0' => { id: existing_child_work.id, _destroy: 'true' } }) }

        it "removes from the members" do
          expect { middleware.update(env) }
            .to change { env.curation_concern.member_ids }
            .from([Valkyrie::ID.new(existing_child_work.id)])
            .to be_empty
        end
      end

      context 'when adding a duplicate member' do
        it "does nothing" do
          expect { middleware.update(env) }
            .not_to change { env.curation_concern.member_ids }
        end
      end

      context 'when adding a new member' do
        let(:another_work) { create(:work, user: depositor) }
        let(:attributes) { HashWithIndifferentAccess.new(work_members_attributes: { '0' => { id: another_work.id } }) }

        it 'adds successfully' do
          expect { middleware.update(env) }
            .to change { env.curation_concern.member_ids }
            .from([Valkyrie::ID.new(existing_child_work.id)])
            .to [Valkyrie::ID.new(existing_child_work.id),
                 Valkyrie::ID.new(another_work.id)]
        end

        context 'and the ability cannot edit' do
          let(:another_work) { create(:work) }

          it "does nothing" do
            expect { middleware.update(env) }
              .not_to change { env.curation_concern.member_ids }
          end
        end
      end
    end
  end
end
