# frozen_string_literal: true
RSpec.describe Hyrax::Actors::ApplyOrderActor, :active_fedora do
  let(:curation_concern) { create(:work_with_two_children, user: user) }
  let(:ability) { ::Ability.new(user) }
  let(:user) { create(:admin) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:env) { Hyrax::Actors::Environment.new(curation_concern, ability, attributes) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
      middleware.use Hyrax::Actors::GenericWorkActor
    end
    stack.build(terminator)
  end

  describe '#update' do
    context 'with ordered_member_ids that are already associated with the parent' do
      let(:attributes) { { ordered_member_ids: ["BlahBlah1"] } }

      before do
        allow(terminator).to receive(:update).with(Hyrax::Actors::Environment).and_return(true)
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
      end
      it "attaches the parent" do
        expect(subject.update(env)).to be true
      end
    end
  end

  describe '#update' do
    let(:user) { create(:admin) }
    let(:curation_concern) { create(:work_with_one_child, user: user) }
    let(:child) { GenericWork.new }

    context 'with ordered_members_ids that arent associated with the curation concern yet.' do
      let(:attributes) { { ordered_member_ids: [child.id] } }
      let(:root_actor) { double }

      before do
        allow(terminator).to receive(:update).with(Hyrax::Actors::Environment).and_return(true)
        # TODO: This can be moved into the Factory
        child.title = ["Generic Title"]
        child.apply_depositor_metadata(user.user_key)
        child.save!
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
      end

      it "attaches the parent" do
        expect(subject.update(env)).to be true
      end
    end

    context 'without an ordered_member_id that was associated with the curation concern' do
      let(:curation_concern) { create(:work_with_two_children, user: user) }
      let(:attributes) { { ordered_member_ids: ["BlahBlah2"] } }

      before do
        allow(terminator).to receive(:update).with(Hyrax::Actors::Environment).and_return(true)
        child.title = ["Generic Title"]
        child.apply_depositor_metadata(user.user_key)
        child.save!
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
      end
      it "removes the first child" do
        expect(subject.update(env)).to be true
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

      before do
        allow(terminator).to receive(:update).with(Hyrax::Actors::Environment).and_return(true)
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
      end

      it "does not attach the work" do
        expect(subject.update(env)).to be false
      end
    end
  end
end
