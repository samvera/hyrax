# frozen_string_literal: true
RSpec.describe Hyrax::AdminSetCreateService do
  let(:user) { FactoryBot.create(:user) }
  let(:persister) { Hyrax.persister }
  let(:query_service) { Hyrax.query_service }

  describe '.create_default_admin_set', :clean_repo do
    context "when new admin set persists" do
      it "is a convenience method for .create_default_admin_set!" do
        expect(described_class).to receive(:create_default_admin_set!).and_call_original
        expect(described_class.create_default_admin_set).to eq true
      end
    end

    context "when new admin set fails to persist" do
      before do
        allow(persister).to receive(:save).with(resource: instance_of(Hyrax::AdministrativeSet))
                                          .and_raise(RuntimeError)
      end

      it "returns false" do
        expect(described_class).to receive(:create_default_admin_set!).and_call_original
        expect(described_class.create_default_admin_set).to eq false
      end
    end
  end

  describe '.find_or_create_default_admin_set', :clean_repo do
    context "when default admin set doesn't exist yet" do
      it "is a convenience method for .create_default_admin_set!" do
        expect(query_service).to receive(:find_by).with(id: described_class::DEFAULT_ID)
                                                  .and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        expect(described_class).to receive(:create_default_admin_set!).and_call_original
        expect(query_service).to receive(:find_by).with(id: anything).and_call_original # permission template
        admin_set = described_class.find_or_create_default_admin_set
        expect(admin_set.title).to eq described_class::DEFAULT_TITLE
      end

      it 'sets up an active workflow' do
        described_class.find_or_create_default_admin_set
        expect(Sipity::Workflow.find_active_workflow_for(admin_set_id: AdminSet::DEFAULT_ID))
          .to be_persisted
      end
    end

    context "when default admin set already exists" do
      let(:default_admin_set) { FactoryBot.valkyrie_create(:default_hyrax_admin_set) }

      it "returns existing default admin set" do
        expect(query_service).to receive(:find_by).with(id: described_class::DEFAULT_ID)
                                                  .and_return(default_admin_set)
        expect(described_class).not_to receive(:create_default_admin_set!)
        admin_set = described_class.find_or_create_default_admin_set
        expect(admin_set.title).to eq described_class::DEFAULT_TITLE
      end
    end
  end

  describe ".default_admin_set?" do
    it "is true for the default admin set id" do
      expect(described_class.default_admin_set?(id: described_class::DEFAULT_ID))
        .to eq true
    end

    it "is false for anything else" do
      expect(described_class.default_admin_set?(id: 'anythingelse')).to eq false
    end
  end

  describe ".call" do
    context "when passing in the default admin set", :clean_repo do
      let(:admin_set) { FactoryBot.build(:default_hyrax_admin_set) }
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
      let(:admin_set) { FactoryBot.build(:default_hyrax_admin_set) }
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
        let(:permission_template) { Hyrax::PermissionTemplate.find_by(source_id: admin_set.id) }
        let(:grants) { permission_template.access_grants }
        let(:available_workflows) { [create(:workflow), create(:workflow)] }

        # rubocop:disable RSpec/AnyInstance
        before do
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

        it 'creates the admin set' do
          updated_admin_set = service.create!
          expect(updated_admin_set).to be_kind_of Hyrax::AdministrativeSet
          expect(updated_admin_set.persisted?).to be true
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

        it 'will not call the workflow_importer' do
          expect { service.create! }.to raise_error(RuntimeError)
          expect(workflow_importer).not_to have_received(:call)
        end
      end
    end
  end
end
