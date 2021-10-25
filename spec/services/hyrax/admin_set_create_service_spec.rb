# frozen_string_literal: true
RSpec.describe Hyrax::AdminSetCreateService do
  let(:user) { FactoryBot.create(:user) }
  let(:persister) { Hyrax.persister }
  let(:query_service) { Hyrax.query_service }

  describe '.create_default_admin_set', :clean_repo do
    subject(:status) { described_class.create_default_admin_set }

    context "when new admin set persists" do
      it "is a convenience method for .create_default_admin_set!" do
        expect(described_class).to receive(:create_default_admin_set!).and_call_original
        expect(status).to eq true
      end
    end

    context "when new admin set fails to persist" do
      before do
        allow(persister).to receive(:save).with(resource: instance_of(Hyrax::AdministrativeSet))
                                          .and_raise(RuntimeError)
      end

      it "returns false" do
        expect(described_class).to receive(:create_default_admin_set!).and_call_original
        expect(status).to eq false
      end
    end
  end

  describe '.find_or_create_default_admin_set', :clean_repo do
    let(:default_admin_set) { FactoryBot.build(:default_hyrax_admin_set) }

    subject(:admin_set) { described_class.find_or_create_default_admin_set }

    context "when default admin set doesn't exist yet" do
      it "is a convenience method for .create_default_admin_set!" do
        expect(query_service).to receive(:find_by).with(id: described_class::DEFAULT_ID)
                                                  .and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        expect(described_class).to receive(:create_default_admin_set!).and_call_original
        expect(query_service).to receive(:find_by).with(id: anything).and_call_original # permission template
        expect(admin_set.title).to eq described_class::DEFAULT_TITLE
      end
    end

    context "when default admin set already exists" do
      let(:default_admin_set) { FactoryBot.valkyrie_create(:default_hyrax_admin_set) }

      it "returns existing default admin set" do
        expect(query_service).to receive(:find_by).with(id: described_class::DEFAULT_ID)
                                                  .and_return(default_admin_set)
        expect(described_class).not_to receive(:create_default_admin_set!)
        expect(admin_set.title).to eq described_class::DEFAULT_TITLE
      end
    end
  end

  describe ".default_admin_set?" do
    let(:admin_set) { FactoryBot.build(:default_hyrax_admin_set) }
    context "when admin_set is the default" do
      it "returns true" do
        expect(described_class.default_admin_set?(id: admin_set.id)).to eq true
      end
    end

    context "when admin_set isn't the default" do
      let(:admin_set) { FactoryBot.build(:hyrax_admin_set, title: ['test']) }
      it "returns false" do
        expect(described_class.default_admin_set?(id: admin_set.id)).to eq false
      end
    end
  end

  describe ".call" do
    subject { described_class.call(admin_set: admin_set, creating_user: user) }

    let(:admin_set) { FactoryBot.build(:hyrax_admin_set, title: ['test']) }

    context "when using the default admin set", :clean_repo do
      let(:admin_set) { FactoryBot.build(:hyrax_admin_set, id: described_class::DEFAULT_ID) }

      it 'will raise RuntimeError if you attempt to a default admin set' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    it "is a convenience method for .new#create!" do
      service = instance_double(described_class)
      expect(described_class).to receive(:new).and_return(service)
      expect(service).to receive(:create!)
      subject
    end
  end

  describe ".call!" do
    subject { described_class.call!(admin_set: admin_set, creating_user: user) }

    let(:admin_set) { FactoryBot.build(:hyrax_admin_set, title: ['test']) }

    context "when using the default admin set", :clean_repo do
      let(:admin_set) { FactoryBot.build(:hyrax_admin_set, id: described_class::DEFAULT_ID) }

      it 'will raise RuntimeError if you attempt to a default admin set' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    it "is a convenience method for .new#create!" do
      service = instance_double(described_class)
      expect(described_class).to receive(:new).and_return(service)
      expect(service).to receive(:create!)
      subject
    end
  end

  describe "an instance" do
    subject { service }

    let(:workflow_importer) { double(call: true) }
    let(:admin_set) { FactoryBot.build(:hyrax_admin_set, title: ['test']) }
    let(:service) { described_class.new(admin_set: admin_set, creating_user: user, workflow_importer: workflow_importer) }

    its(:default_workflow_importer) { is_expected.to respond_to(:call) }

    describe "#create" do
      subject { service.create }

      context "when the admin_set is valid" do
        let(:updated_admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set) }

        it "is a convenience method for #create! that returns true" do
          expect(service).to receive(:create!).and_return(updated_admin_set)
          expect(subject).to eq true
        end
      end

      context "when the admin_set is invalid" do
        it "is a convenience method for #create! that returns false" do
          expect(service).to receive(:create!).and_raise(RuntimeError)
          expect(subject).to eq false
        end
      end
    end

    describe "#create!" do
      let(:admin_set) { AdminSet.new(title: ['test']) }

      subject { service.create! }

      context "when the admin_set is valid" do
        let(:permission_template) { Hyrax::PermissionTemplate.find_by(source_id: admin_set.id) }
        let(:grants) { permission_template.access_grants }
        let(:available_workflows) { [create(:workflow), create(:workflow)] }

        # rubocop:disable RSpec/AnyInstance
        before do
          allow_any_instance_of(Hyrax::PermissionTemplate).to receive(:available_workflows).and_return(available_workflows)
          # Load expected Sipity roles, which were likely cleaned by DatabaseCleaner
          Hyrax.config.persist_registered_roles!
        end
        # rubocop:enable RSpec/AnyInstance

        it "creates an AdministrativeSet, PermissionTemplate, Workflows, activates the default workflow, and sets access" do
          expect(Sipity::Workflow).to receive(:activate!).with(permission_template: kind_of(Hyrax::PermissionTemplate), workflow_name: Hyrax.config.default_active_workflow_name)
          expect do
            expect(subject).to be_kind_of Hyrax::AdministrativeSet
          end.to change { admin_set.persisted? }.from(false).to(true)
                                                .and change { Sipity::WorkflowResponsibility.count }.by(12)
          # 12 responsibilities because:
          #  * 2 agents (user + admin group), multiplied by
          #  * 2 available workflows, multiplied by
          #  * 3 roles (from Hyrax::RoleRegistry), equals
          #  * 12
          expect(admin_set.edit_users).to match_array([user.user_key])
          expect(admin_set.edit_groups).to match_array(['admin'])
          expect(admin_set.read_users).to match_array([])
          expect(admin_set.read_groups).not_to include('public')
          expect(admin_set.creator).to eq [user.user_key]

          expect(workflow_importer).to have_received(:call).with(permission_template: permission_template)
          expect(permission_template).to be_persisted
          expect(grants.count).to eq 2
          expect(grants.pluck(:agent_type)).to include('group', 'user')
          expect(grants.pluck(:agent_id)).to include('admin', user.user_key)
          expect(grants.pluck(:access)).to include('manage')
        end
      end

      context "when the admin_set is invalid" do
        let(:admin_set) { FactoryBot.build(:invalid_hyrax_admin_set) } # Missing title

        it 'will not call the workflow_importer' do
          expect { subject }.to raise_error(RuntimeError)
          expect(workflow_importer).not_to have_received(:call)
        end
      end
    end
  end
end
