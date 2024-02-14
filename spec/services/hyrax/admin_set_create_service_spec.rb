# frozen_string_literal: true
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::AdminSetCreateService do
  let(:user) { FactoryBot.create(:user) }
  let(:persister) { Hyrax.persister }
  let(:query_service) { Hyrax.query_service }

  describe '.find_or_create_default_admin_set', :clean_repo do
    context "when default admin set doesn't exist yet" do
      it "is a convenience method for .create_default_admin_set!" do
        unless Hyrax.config.disable_wings
          expect(query_service).to receive(:find_by).with(id: described_class::DEFAULT_ID)
                                                    .and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        end
        expect(described_class).to receive(:create_default_admin_set!).and_call_original
        expect(query_service).to receive(:find_by).with(id: anything).at_least(1).times.and_call_original # permission template
        admin_set = described_class.find_or_create_default_admin_set
        expect(admin_set.title).to eq described_class::DEFAULT_TITLE
      end

      it 'sets up an active workflow' do
        described_class.find_or_create_default_admin_set
        unless Hyrax.config.disable_wings
          expect(Sipity::Workflow.find_active_workflow_for(admin_set_id: AdminSet::DEFAULT_ID))
            .to be_persisted
        end
      end
    end

    context "and Hyrax::DefaultAdministrativeSet table does not exist" do
      before { allow(Hyrax::DefaultAdministrativeSet).to receive(:save_supported?).and_return(false) }
      it "creates a default admin set with the DEFAULT_ID" do
        expect(Hyrax::DefaultAdministrativeSet).not_to receive(:first)
        expect(described_class.find_or_create_default_admin_set.id).to eq described_class::DEFAULT_ID unless Hyrax.config.disable_wings
      end
    end

    context "when default admin set id is NOT saved in the database", :active_fedora do
      before { allow(Hyrax::DefaultAdministrativeSet).to receive(:count).and_return(0) }
      context "but default admin set does exist" do
        let(:default_admin_set) do
          FactoryBot.valkyrie_create(:default_hyrax_admin_set,
                                     with_persisted_default_id: false)
        end
        let(:new_record) do
          instance_double(Hyrax::DefaultAdministrativeSet,
                          id: 1,
                          default_admin_set_id: default_admin_set.id)
        end

        it "saves the id of the existing default_admin_set and returns existing default admin set" do
          expect(described_class).not_to receive(:create_default_admin_set!)
          expect(Hyrax::DefaultAdministrativeSet)
            .to receive(:new)
            .with(default_admin_set_id: default_admin_set.id.to_s)
            .and_return(new_record)
          expect(new_record).to receive(:save)
          expect(described_class.find_or_create_default_admin_set).to eq default_admin_set
        end
      end

      context "and default admin set doesn't exist", :active_fedora do
        before do
          allow(query_service).to receive(:find_by)
            .with(id: described_class::DEFAULT_ID)
            .and_raise(Valkyrie::Persistence::ObjectNotFoundError)
          allow(query_service).to receive(:find_by)
            .with(id: anything).and_call_original # permission template
        end
        let(:collection_type) { FactoryBot.create(:admin_set_collection_type) }
        let(:new_default_admin_set) do
          FactoryBot.build(:hyrax_admin_set,
                           id: Valkyrie::ID.new('123'),
                           title: described_class::DEFAULT_TITLE)
        end
        let(:new_record) do
          instance_double(Hyrax::DefaultAdministrativeSet,
                          id: 1,
                          default_admin_set_id: new_default_admin_set.id)
        end

        it "creates a default admin set and saves the id and returns new default admin set" do
          expect(described_class).to receive(:create_admin_set)
            .with(suggested_id: described_class::DEFAULT_ID, title: described_class::DEFAULT_TITLE)
            .and_return(new_default_admin_set)
          expect(Hyrax::DefaultAdministrativeSet).to receive(:new)
            .with(default_admin_set_id: new_default_admin_set.id)
            .and_return(new_record)
          expect(new_record).to receive(:save)
          expect(described_class.find_or_create_default_admin_set.id).to eq '123'
        end
      end
    end

    context "when default admin set id is saved in the database", :active_fedora do
      let!(:default_admin_set) do
        FactoryBot.valkyrie_create(:default_hyrax_admin_set,
                                   id: Valkyrie::ID.new('234'),
                                   title: described_class::DEFAULT_TITLE)
      end

      it "returns admin set for saved id" do
        expect(described_class.find_or_create_default_admin_set.id).to eq '234'
      end
    end
  end

  describe ".default_admin_set?" do
    let!(:admin_set) do
      if Hyrax.config.disable_wings
        FactoryBot.valkyrie_create(:default_hyrax_admin_set, id: nil)
      else
        FactoryBot.valkyrie_create(:default_hyrax_admin_set)
      end
    end
    let!(:def_id) { Hyrax.config.disable_wings ? admin_set.id.to_s : described_class::DEFAULT_ID }

    it "is true for the default admin set id" do
      expect(described_class.default_admin_set?(id: def_id))
        .to eq true
    end

    it "is false for anything else" do
      expect(described_class.default_admin_set?(id: 'anythingelse')).to eq false
    end
  end

  describe ".call" do
    context "when passing in the default admin set", :clean_repo do
      let(:admin_set) { FactoryBot.valkyrie_create(:default_hyrax_admin_set, id: nil) }
      it 'will raise RuntimeError' do
        expect { described_class.call(admin_set: admin_set, creating_user: user) }
          .to raise_error(RuntimeError)
      end
    end

    context "when passing a non-default admin set" do
      let(:admin_set) { FactoryBot.build(:hyrax_admin_set) }
      it "is a convenience method for .call!" do
        service = instance_double(described_class)
        expect(described_class).to receive(:new).and_return(service)
        expect(service).to receive(:create!)
        described_class.call(admin_set: admin_set, creating_user: user)
      end
    end
  end

  describe ".call!" do
    context "when passing in the default admin set", :clean_repo do
      let(:admin_set) { FactoryBot.valkyrie_create(:default_hyrax_admin_set, id: nil) }
      it 'will raise RuntimeError' do
        expect { described_class.call!(admin_set: admin_set, creating_user: user) }
          .to raise_error(RuntimeError)
      end
    end

    context "when passing a non-default admin set" do
      let(:admin_set) { FactoryBot.build(:hyrax_admin_set) }
      it "is a convenience method for .new#create!" do
        service = instance_double(described_class)
        expect(described_class).to receive(:new).and_return(service)
        expect(service).to receive(:create!)
        described_class.call!(admin_set: admin_set, creating_user: user)
      end
    end
  end

  describe "an instance" do
    subject { service }
    let(:service) { described_class.new(admin_set: admin_set, creating_user: user, workflow_importer: workflow_importer) }
    let(:workflow_importer) { double(call: true) }
    let(:admin_set) { FactoryBot.build(:hyrax_admin_set, title: ['test']) }

    its(:default_workflow_importer) { is_expected.to respond_to(:call) }

    describe "#create" do
      context "when the admin_set is valid" do
        let(:updated_admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set) }

        it "is a convenience method for #create! that returns true" do
          expect(service).to receive(:create!).and_return(updated_admin_set)
          expect(service.create).to eq true
        end
      end

      context "when the admin_set is invalid" do
        it "is a convenience method for #create! that returns false" do
          expect(service).to receive(:create!).and_raise(RuntimeError)
          expect(service.create).to eq false
        end
      end
    end

    describe "#create!" do
      let(:admin_set) { FactoryBot.build(:hyrax_admin_set) }

      context "when the admin_set is valid" do
        let(:listener) { Hyrax::Specs::SpyListener.new }
        let(:permission_template) { Hyrax::PermissionTemplate.find_by(source_id: admin_set.id) }
        let(:grants) { permission_template.access_grants }
        let(:available_workflows) { [create(:workflow), create(:workflow)] }

        # rubocop:disable RSpec/AnyInstance
        before do
          Hyrax.publisher.subscribe(listener)
          allow_any_instance_of(Hyrax::PermissionTemplate)
            .to receive(:available_workflows).and_return(available_workflows)
          allow(Sipity::Workflow)
            .to receive(:activate!)
            .with(permission_template: kind_of(Hyrax::PermissionTemplate),
                  workflow_name: Hyrax.config.default_active_workflow_name)
          # Load expected Sipity roles, which were likely cleaned by DatabaseCleaner
          Hyrax.config.persist_registered_roles!
        end
        # rubocop:enable RSpec/AnyInstance

        after { Hyrax.publisher.unsubscribe(listener) }

        it 'creates the admin set' do
          updated_admin_set = service.create!
          expect(updated_admin_set).to be_kind_of Hyrax::AdministrativeSet
          expect(updated_admin_set.persisted?).to be true
        end

        it 'publishes a change to collection metadata' do
          expect { service.create! }
            .to change { listener.collection_metadata_updated&.payload }
        end

        it 'sets creator' do
          updated_admin_set = service.create!
          expect(updated_admin_set.creator).to eq [user.user_key]
        end

        it 'grants edit access to creator and admins' do
          updated_admin_set = service.create!
          expect(updated_admin_set.edit_users).to match_array([user.user_key])
          expect(updated_admin_set.edit_groups).to match_array(['admin'])
        end

        it 'does not grant any read access' do
          updated_admin_set = service.create!
          expect(updated_admin_set.read_users).to match_array([])
          expect(updated_admin_set.read_groups).to match_array([])
        end

        it 'creates Sipity::Agents for the admin group and creator user' do
          service.create!
          expect(Sipity::Agent.where(proxy_for_type: 'Hyrax::Group').pluck(:proxy_for_id))
            .to include('admin')
          expect(Sipity::Agent.where(proxy_for_type: 'User').pluck(:proxy_for_id))
            .to include(user.id.to_s)
        end

        it 'sets up a permission template' do
          updated_admin_set = service.create!
          expect(Hyrax::PermissionTemplate.find_by(source_id: updated_admin_set.id.to_s))
            .to be_persisted
        end

        it 'gives permission template access grants to admin and depositor' do
          updated_admin_set = service.create!
          template = Hyrax::PermissionTemplate.find_by(source_id: updated_admin_set.id.to_s)
          expect(template.access_grants)
            .to contain_exactly(have_attributes(agent_type: 'group', agent_id: 'admin', access: 'manage'),
                                have_attributes(agent_type: 'user', agent_id: user.user_key, access: 'manage'))
        end

        it 'sets up workflow responsibilities' do
          # 12 responsibilities because:
          #  * 2 agents (user + admin group), multiplied by
          #  * 2 available workflows, multiplied by
          #  * 3 roles (from Hyrax::RoleRegistry), equals
          #  * 12
          expect do
            expect(service.create!).to be_kind_of Hyrax::AdministrativeSet
          end.to change { Sipity::WorkflowResponsibility.count }.by(12)
        end
      end

      context "when the admin_set is invalid" do
        let(:admin_set) { FactoryBot.build(:invalid_hyrax_admin_set) } # Missing title

        it 'will not find the sipity workflow' do
          expect { service.create! }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
