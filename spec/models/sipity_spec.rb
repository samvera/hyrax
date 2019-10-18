RSpec.describe Sipity do
  describe '.Entity' do
    context "with a Sipity::Entity" do
      let(:object) { Sipity::Entity.new }

      it { expect(described_class.Entity(object)).to eq object }
    end

    context "with a Sipity::Comment" do
      let(:object) { Sipity::Comment.new(entity: entity) }
      let(:entity) { Sipity::Entity.new }

      it { expect(described_class.Entity(object)).to eq entity }
    end

    context "with a SolrDocument" do
      let(:object) { SolrDocument.new(id: '9999', has_model_ssim: ["GenericWork"]) }
      let(:workflow_state) { create(:workflow_state) }
      let!(:entity) do
        Sipity::Entity.create(proxy_for_global_id: 'gid://internal/GenericWork/9999',
                              workflow_state: workflow_state,
                              workflow: workflow_state.workflow)
      end

      it { expect(described_class.Entity(object)).to eq entity }
    end

    context 'a Work' do
      let(:workflow_state) { create(:workflow_state) }

      it 'will raise an conversion error if an id has not been assigned' do
        object = build(:generic_work)

        expect { described_class.Entity(object) }
          .to raise_error Sipity::ConversionError
      end

      it 'raises a conversion error when there is no matching entity' do
        object = create(:generic_work)

        expect { described_class.Entity(object) }
          .to raise_error Sipity::ConversionError
      end

      it 'gives a matching entity' do
        object = create(:generic_work)

        entity = Sipity::Entity.create(proxy_for_global_id: object.to_global_id,
                                       workflow_state: workflow_state,
                                       workflow: workflow_state.workflow)

        expect(described_class.Entity(object)).to eq entity
      end
    end

    it 'will return the to_processing_entity if the object responds to the processing entity' do
      object = double(to_sipity_entity: :processing_entity)
      expect(described_class.Entity(object)).to eq(:processing_entity)
    end

    it 'will raise an error if it cannot convert' do
      expect { described_class.Entity(nil) }
        .to raise_error PowerConverter::ConversionError
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
end
