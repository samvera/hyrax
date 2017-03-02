require 'spec_helper'

RSpec.describe Hyrax::DefaultAdminSetActor do
  let(:next_actor) do
    double('next actor', create: true,
                         curation_concern: work,
                         update: true,
                         user: depositor)
  end
  let(:actor) do
    Hyrax::Actors::ActorStack.new(work, depositor_ability, [described_class])
  end
  let(:depositor) { create(:user) }
  let(:depositor_ability) { ::Ability.new(depositor) }
  let(:work) { build(:generic_work) }
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }

  describe "create" do
    before do
      allow(Hyrax::Actors::RootActor).to receive(:new).and_return(next_actor)
    end

    context "when admin_set_id is blank" do
      let(:attributes) { { admin_set_id: '' } }
      let(:default_id) { AdminSet::DEFAULT_ID }

      it "creates the default AdminSet with a PermissionTemplate and an ActiveWorkflow then calls the next actor with the default admin set id" do
        expect(next_actor).to receive(:create).with(admin_set_id: default_id).and_return(true)
        expect(AdminSet).to receive(:find_or_create_default_admin_set_id).and_return(default_id)
        actor.create(attributes)
      end
    end

    context "when admin_set_id is provided" do
      let(:attributes) { { admin_set_id: admin_set.id } }

      it "uses the provided id, ensures a permission template, and returns true" do
        expect(next_actor).to receive(:create).with(attributes).and_return(true)
        expect(AdminSet).not_to receive(:find_or_create_default_admin_set_id)
        expect do
          expect(actor.create(attributes)).to be true
        end.to change { Hyrax::PermissionTemplate.count }.by(1)
      end
    end
  end
end
