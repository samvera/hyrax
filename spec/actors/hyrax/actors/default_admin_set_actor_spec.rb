require 'spec_helper'

RSpec.describe Hyrax::Actors::DefaultAdminSetActor do
  let(:depositor) { create(:user) }
  let(:depositor_ability) { ::Ability.new(depositor) }
  let(:work) { build(:generic_work) }
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }
  let(:env) { Hyrax::Actors::Environment.new(work, depositor_ability, attributes) }

  describe "create" do
    let(:terminator) { Hyrax::Actors::Terminator.new }
    subject(:middleware) do
      stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
        middleware.use described_class
      end
      stack.build(terminator)
    end

    context "when admin_set_id is blank" do
      let(:attributes) { { admin_set_id: '' } }
      let(:default_id) { AdminSet::DEFAULT_ID }

      it "creates the default AdminSet with a PermissionTemplate and an ActiveWorkflow then calls the next actor with the default admin set id" do
        expect(terminator).to receive(:create).with(Hyrax::Actors::Environment) do |k|
          expect(k.attributes).to eq(admin_set_id: default_id)
          true
        end
        expect(AdminSet).to receive(:find_or_create_default_admin_set_id).and_return(default_id)
        middleware.create(env)
      end
    end

    context "when admin_set_id is provided" do
      let(:attributes) { { admin_set_id: admin_set.id } }

      it "uses the provided id, ensures a permission template, and returns true" do
        expect(terminator).to receive(:create).with(Hyrax::Actors::Environment) do |k|
          expect(k.attributes).to eq(attributes)
          true
        end
        expect(AdminSet).not_to receive(:find_or_create_default_admin_set_id)
        expect do
          expect(middleware.create(env)).to be true
        end.to change { Hyrax::PermissionTemplate.count }.by(1)
      end
    end
  end
end
