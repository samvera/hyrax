# frozen_string_literal: true
RSpec.describe Sipity do
  describe '.Agent' do
    it 'will convert a Sipity::Agent' do
      object = Sipity::Agent.new
      expect(described_class.Agent(object)).to eq(object)
    end

    it 'will convert an object that responds to #to_sipity_agent' do
      object = double(to_sipity_agent: :a_sipity_agent)
      expect(described_class.Agent(object)).to eq(:a_sipity_agent)
    end

    it 'will raise an exception if it cannot convert the given object' do
      expect { described_class.Agent(double) }
        .to raise_error(Sipity::ConversionError)
    end
  end

  describe '.Entity' do
    context "with a Sipity::Entity" do
      let(:object) { Sipity::Entity.new }

      it { expect(described_class.Entity(object)).to eq object }
    end

    # NOTE: Since this is testing an ActiveFedora object parsed into a Valkyrie object, this has been marked as
    #   ActiveFedora-only.
    context "with a Sipity::Entity that doesn't match the globalID for a valkyrie object", :active_fedora do
      let(:object) { FactoryBot.create(:generic_work, id: '9999').valkyrie_resource }
      let(:workflow_state) { create(:workflow_state) }
      let!(:entity) do
        Sipity::Entity.create(proxy_for_global_id: "gid://#{GlobalID.app}/GenericWork/9999",
                              workflow_state: workflow_state,
                              workflow: workflow_state.workflow)
      end

      it { expect(described_class.Entity(object)).to eq entity }
    end

    context "with a Sipity::Comment" do
      let(:object) { Sipity::Comment.new(entity: entity) }
      let(:entity) { Sipity::Entity.new }

      it { expect(described_class.Entity(object)).to eq entity }
    end

    context "with a SolrDocument" do
      let(:object) { SolrDocument.new(id: '9999', has_model_ssim: ["GenericWork"]) }
      let(:workflow_state) { FactoryBot.create(:workflow_state) }
      let!(:entity) do
        gid_class_string = if GenericWork < Valkyrie::Resource
                             "Hyrax::ValkyrieGlobalIdProxy"
                           else
                             "GenericWork"
                           end

        Sipity::Entity.create(proxy_for_global_id: "gid://#{GlobalID.app}/#{gid_class_string}/9999",
                              workflow_state: workflow_state,
                              workflow: workflow_state.workflow)
      end

      it { expect(described_class.Entity(object)).to eq entity }
    end

    context 'a Work' do
      let(:workflow_state) { create(:workflow_state) }

      it 'will raise an conversion error if an id has not been assigned' do
        object = build(:hyrax_work)

        expect { described_class.Entity(object) }
          .to raise_error Sipity::ConversionError
      end

      it 'raises a conversion error when there is no matching entity' do
        object = valkyrie_create(:hyrax_work)

        expect { described_class.Entity(object) }
          .to raise_error Sipity::ConversionError
      end

      it 'gives a matching entity' do
        object = valkyrie_create(:hyrax_work)

        entity = Sipity::Entity.create(proxy_for_global_id: Hyrax::GlobalID(object).to_s,
                                       workflow_state: workflow_state,
                                       workflow: workflow_state.workflow)

        expect(described_class.Entity(object)).to eq entity
      end
    end

    it 'will return the to_sipity_entity if the object responds to that method' do
      object = double(to_sipity_entity: :processing_entity)
      expect(described_class.Entity(object)).to eq(:processing_entity)
    end

    it 'will raise an error if it cannot convert' do
      expect { described_class.Entity(nil) }
        .to raise_error Sipity::ConversionError
    end
  end

  describe '.Role' do
    it "converts Sipity::Role" do
      object = Sipity::Role.new
      expect(described_class.Role(object)).to eq object
    end

    it "converts a #to_sipity_role object" do
      object = double(to_sipity_role: Sipity::Role.new)
      expect(described_class.Role(object)).to eq object.to_sipity_role
    end

    it "converts a string to a Sipity::Role if there exists a Sipity::Role with a name equal to the string" do
      Sipity::Role.create!(name: 'hello')
      expect(described_class.Role('hello')).to be_a(Sipity::Role)
    end

    it "creates a new role if given a string and no Sipity::Role exists with that name" do
      expect { described_class.Role('new_role_name') }.to change { Sipity::Role.count }.by(1)
    end

    it "converts a base object with composed attributes delegator" do
      base_object = Sipity::Role.new
      expect(described_class.Role(base_object)).to eq(base_object)
    end

    it 'does not convert an arbitrary object' do
      expect { described_class.Role(double) }.to raise_error(Sipity::ConversionError)
    end
  end

  describe '.WorkflowAction' do
    let(:workflow_id) { 1 }
    let(:action) { Sipity::WorkflowAction.new(id: 4, name: 'show', workflow_id: workflow_id) }

    context "with workflow_id and action's workflow_id matching" do
      it 'will return the object if it is a Sipity::WorkflowAction' do
        expect(described_class.WorkflowAction(action, workflow_id)).to eq(action)
      end

      it 'will return the object if it responds to #to_sipity_action' do
        object = double(to_sipity_action: action)
        expect(described_class.WorkflowAction(object, workflow_id)).to eq(action)
      end

      it 'will raise an error if it cannot convert the object' do
        object = double
        expect { described_class.WorkflowAction(object, workflow_id) }
          .to raise_error(Sipity::ConversionError)
      end

      it 'will use a found action based on the given string and workflow_id' do
        expect(Sipity::WorkflowAction).to receive(:find_by).and_return(action)
        expect(described_class.WorkflowAction(action.name, workflow_id)).to eq(action)
      end

      context "when the WorkflowAction can not be found" do
        it 'will raise an error' do
          expect(Sipity::WorkflowAction).to receive(:find_by).and_return(nil)
          expect { described_class.WorkflowAction(action.name, workflow_id) }
            .to raise_error(Sipity::ConversionError)
        end
      end
    end

    context "with mismatching workflow_id and action's workflow_id" do
      it "will fail an error if the scope's workflow_id is different than the actions" do
        expect { described_class.WorkflowAction(action, workflow_id + 1) }
          .to raise_error(Sipity::ConversionError)
      end
    end
  end

  describe '.WorkflowState' do
    let(:workflow_state) { Sipity::WorkflowState.new(id: 1, name: 'hello') }
    let(:workflow) { create(:workflow) }

    it 'will convert a Sipity::WorkflowState' do
      expect(described_class.WorkflowState(workflow_state, workflow))
        .to eq workflow_state
    end

    it 'will convert a string based on scope' do
      state = create(:workflow_state, workflow_id: workflow.id, name: 'hello')

      expect(described_class.WorkflowState('hello', workflow))
        .to eq state
    end

    it 'will attempt convert a string based on scope' do
      expect { described_class.WorkflowState('missing', workflow) }
        .to raise_error(Sipity::ConversionError)
    end
  end
end
