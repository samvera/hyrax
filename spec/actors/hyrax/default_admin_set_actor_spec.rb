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
        expect(Hyrax::AdminSetCreateService).to receive(:call).with(kind_of(AdminSet), depositor)
        actor.create(attributes)
      end
    end

    context "when admin_set_id is provided" do
      let(:attributes) { { admin_set_id: admin_set.id } }

      it "uses the provided id and returns true" do
        expect(next_actor).to receive(:create).with(attributes).and_return(true)
        expect(actor.create(attributes)).to be true
      end
    end
  end

  describe "#create_default_admin_set" do
    let(:actor) { described_class.new(double, double, next_actor) }
    context "when another thread has already created the admin set" do
      it "doesn't raise an error" do
        expect(Hyrax::AdminSetCreateService).to receive(:call).and_raise(ActiveFedora::IllegalOperation)
        expect { actor.send(:create_default_admin_set) }.not_to raise_error
      end
    end
  end
end
