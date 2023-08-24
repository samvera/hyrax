# frozen_string_literal: true
RSpec.describe Hyrax::Actors::DefaultAdminSetActor, :active_fedora do
  let(:depositor) { build(:user) }
  let(:depositor_ability) { ::Ability.new(depositor) }
  let(:work) { build(:generic_work) }
  let(:admin_set) { build(:admin_set, id: 'admin_set_1') }
  let(:permission_template) { create(:permission_template, source_id: admin_set.id) }
  let(:env) { Hyrax::Actors::Environment.new(work, depositor_ability, attributes) }

  let(:terminator) { Hyrax::Actors::Terminator.new }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  describe "#create" do
    context "when admin_set_id is blank" do
      let(:attributes) { { admin_set_id: '' } }
      let(:default_id) { AdminSet::DEFAULT_ID }

      it "creates the default AdminSet with a PermissionTemplate and an ActiveWorkflow then calls the next actor with the default admin set id" do
        expect(terminator).to receive(:create).with(Hyrax::Actors::Environment) do |k|
          expect(k.attributes).to eq("admin_set_id" => default_id)
          true
        end
        expect(Hyrax::EnsureWellFormedAdminSetService).to receive(:call).with(admin_set_id: nil).and_return(default_id)
        middleware.create(env)
      end
    end

    context "when admin_set_id is provided" do
      let(:attributes) { { admin_set_id: admin_set.id } }

      it "uses the provided id, ensures a well formed admin set, and returns true" do
        expect(terminator).to receive(:create).with(Hyrax::Actors::Environment) do |k|
          expect(k.attributes).to eq("admin_set_id" => admin_set.id)
          true
        end
        expect(Hyrax::EnsureWellFormedAdminSetService).to receive(:call).with(admin_set_id: admin_set.id).and_return(admin_set.id)
        expect(middleware.create(env)).to be true
      end
    end
  end

  describe '#update' do
    before do
      work.admin_set_id = admin_set.id
    end
    context "when admin_set_id is missing" do
      let(:attributes) { { title: 'new title' } }
      let(:default_id) { AdminSet::DEFAULT_ID }

      it "gets the admin set id for the work" do
        expect(terminator).to receive(:update).with(Hyrax::Actors::Environment) do |k|
          expect(k.attributes).to eq('title' => 'new title', 'admin_set_id' => admin_set.id)
          true
        end
        expect(Hyrax::EnsureWellFormedAdminSetService).to receive(:call).with(admin_set_id: admin_set.id).and_return(admin_set.id)
        expect(middleware.update(env)).to be true
      end
    end

    context "when admin_set_id is provided" do
      let(:admin_set2) { build(:admin_set, id: 'admin_set_2') }
      let(:attributes) { { title: 'new title', admin_set_id: admin_set2.id } }

      it "uses the provided id, ensures ensures a well formed admin set, and returns true" do
        expect(terminator).to receive(:update).with(Hyrax::Actors::Environment) do |k|
          expect(k.attributes).to eq('title' => 'new title', 'admin_set_id' => admin_set2.id)
          true
        end
        expect(Hyrax::EnsureWellFormedAdminSetService).to receive(:call).with(admin_set_id: admin_set2.id).and_return(admin_set2.id)
        expect(middleware.update(env)).to be true
      end
    end
  end
end
