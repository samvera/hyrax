require 'spec_helper'

RSpec.describe Sufia::DefaultAdminSetActor do
  let(:next_actor) do
    double('next actor', create: true,
                         curation_concern: work,
                         update: true,
                         user: depositor)
  end
  let(:actor) do
    CurationConcerns::Actors::ActorStack.new(work, depositor, [described_class])
  end
  let(:depositor) { create(:user) }
  let(:work) { build(:generic_work) }
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }

  describe "create" do
    before do
      allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(next_actor)
    end

    context "when admin_set_id is blank" do
      let(:attributes) { { admin_set_id: '' } }
      let(:default_id) { AdminSet::DEFAULT_ID }

      it "creates the default AdminSet with a PermissionTemplate and calls the next actor with the default admin set id" do
        expect(next_actor).to receive(:create).with(admin_set_id: default_id).and_return(true)
        expect { actor.create(attributes) }.to change { AdminSet.count }.by(1)
          .and change { Sufia::PermissionTemplate.count }.by(1)
      end
    end

    context "when admin_set_id is provided" do
      let(:attributes) { { admin_set_id: admin_set.id } }

      it "uses the provided id, ensures a permission template, and returns true" do
        expect(next_actor).to receive(:create).with(attributes).and_return(true)
        expect do
          expect(actor.create(attributes)).to be true
        end.to change { Sufia::PermissionTemplate.count }.by(1)
      end
    end
  end
end
