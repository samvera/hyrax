require 'spec_helper'
require 'wings'

RSpec.describe ValkyrieTransitionHelper do
  # before do
  #   Valkyrie::MetadataAdapter.register(
  #       Valkyrie::Persistence::Memory::MetadataAdapter.new, :memory_adapter
  #   )
  #   Valkyrie.config.metadata_adapter = :memory_adapter
  # end

  let(:af_object) { FileSet.new }
  let(:resource) { af_object.valkyrie_resource }

  describe ".save" do
    context 'when given an active fedora object' do
      it 'saves the active fedora object using active fedora' do
        expect(af_object).to receive(:save)
        described_class.save(object: af_object)
      end
    end

    context 'when given a valkyrie resource' do
      it 'saves the resource using .save_resource' do
        expect(described_class).to receive(:save_resource).with(resource: resource)
        described_class.save(object: resource)
      end
    end

    context 'when object is neither an active fedora object or a valkyrie resource' do
      it 'raises ArgumentError' do
        expect { described_class.save(object: 'invalid_object') }.to raise_error(ArgumentError, "Object argument must be a Valkyrie::Resource or an ActiveFedora object")
      end
    end
  end

  describe ".save_resource" do
    context 'when passed a resource' do
      context 'and saves without errors' do
        it 'saves the resource' do
          expect(described_class.save_resource(resource: resource)).to be_a Valkyrie::Resource
        end
      end

      context 'and fails to save' do
        before do
          allow_any_instance_of(Wings::Valkyrie::Persister) # rubocop:disable RSpec/AnyInstance
            .to receive(:save)
            .with(resource: resource)
            .and_raise(Wings::Valkyrie::Persister::FailedSaveError, obj: af_object) # TODO: Should not rescue a wings specific exception in Hyrax code
        end

        it 'returns false' do
          expect(described_class.save_resource(resource: resource)).to eq false
        end
      end
    end

    context 'when resource is not a valkyrie resource' do
      it 'raises ArgumentError' do
        expect { described_class.save_resource(resource: af_object) }.to raise_error(ArgumentError, "Resource argument must be a Valkyrie::Resource")
      end
    end
  end

  describe ".reload" do
    context 'when given an active fedora object' do
      it 'reloads the active fedora object using active fedora' do
        expect(af_object).to receive(:reload)
        described_class.reload(object: af_object)
      end
    end

    context 'when given a valkyrie resource' do
      it 'reloads the resource using .reload_resource' do
        expect(described_class).to receive(:reload_resource).with(resource: resource)
        described_class.reload(object: resource)
      end
    end

    context 'when object is neither an active fedora object or a valkyrie resource' do
      it 'raises ArgumentError' do
        expect { described_class.reload(object: 'invalid_object') }.to raise_error(ArgumentError, "Object argument must be a Valkyrie::Resource or an ActiveFedora object")
      end
    end
  end

  describe ".reload_resource" do
    context 'when passed a resource with an id' do
      it 'reloads the resource' do
        expect(described_class.reload_resource(resource: Hyrax.persister.save(resource: resource))).to be_a Valkyrie::Resource
      end
    end

    context 'when resource does not have an id assigned' do
      before { allow(resource).to receive(:id).and_return(nil) }
      it 'raises ArgumentError' do
        expect { described_class.reload_resource(resource: resource) }.to raise_error(ArgumentError, "Resource argument must have an id assigned")
      end
    end

    context 'when resource is not a valkyrie resource' do
      it 'raises ArgumentError' do
        expect { described_class.reload_resource(resource: af_object) }.to raise_error(ArgumentError, "Resource argument must be a Valkyrie::Resource")
      end
    end
  end

  describe ".force_use_valkyrie" do
    context 'when use_valkyrie is true' do
      it 'returns true' do
        expect(described_class.force_use_valkyrie(use_valkyrie: true)).to eq true
      end
    end

    context 'when use_valkyrie is false' do
      context 'and at least one object is a valkyrie object' do
        it 'returns true' do
          expect(described_class.force_use_valkyrie(use_valkyrie: false, objects: [resource])).to eq true
        end
      end

      context 'and none of the objects is a valkyrie object' do
        it 'returns false' do
          expect(described_class.force_use_valkyrie(use_valkyrie: false, objects: [af_object])).to eq false
        end
      end

      context 'and there are no objects' do
        it 'returns false' do
          expect(described_class.force_use_valkyrie(use_valkyrie: false, objects: [])).to eq false
        end
      end
    end
  end

  describe ".to_resource" do
    context 'when object is a valkyrie resource' do
      it 'returns the passed in valkyrie resource' do
        expect(described_class.to_resource(resource)).to eq resource
      end
    end

    context 'when object is an active fedora object' do
      it 'returns a valkyrie resource' do
        expect(described_class.to_resource(af_object)).to be_a Valkyrie::Resource
      end
    end

    context 'when object is neither an active fedora object or a valkyrie resource' do
      it 'raises ArgumentError' do
        expect { described_class.to_resource('invalid_object') }.to raise_error(ArgumentError, "Object argument must be a Valkyrie::Resource or an ActiveFedora object")
      end
    end
  end

  describe ".to_active_fedora" do
    context 'when object is a valkyrie resource' do
      it 'returns a active fedora object' do
        expect(described_class.to_active_fedora(resource)).to be_a ActiveFedora::Base
      end
    end

    context 'when object is an active fedora object' do
      it 'returns the passed in active fedora object' do
        expect(described_class.to_active_fedora(af_object)).to eq af_object
      end
    end

    context 'when object is neither an active fedora object or a valkyrie resource' do
      it 'raises ArgumentError' do
        expect { described_class.to_active_fedora('invalid_object') }.to raise_error(ArgumentError, "Object argument must be a Valkyrie::Resource or an ActiveFedora object")
      end
    end
  end

  describe ".valkyrie_object?" do
    context 'when object is a valkyrie resource' do
      it 'returns true' do
        expect(described_class.valkyrie_object?(resource)).to eq true
      end
    end

    context 'when object is an active fedora object' do
      it 'returns false' do
        expect(described_class.valkyrie_object?(af_object)).to eq false
      end
    end
  end

  describe ".active_fedora_object?" do
    context 'when object is a valkyrie resource' do
      it 'returns false' do
        expect(described_class.active_fedora_object?(resource)).to eq false
      end
    end

    context 'when object is an active fedora object' do
      it 'returns true' do
        expect(described_class.active_fedora_object?(af_object)).to eq true
      end
    end
  end
end
