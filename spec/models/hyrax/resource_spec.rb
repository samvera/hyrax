# frozen_string_literal: true

require 'hyrax/specs/shared_specs/hydra_works'
require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::Resource do
  subject(:resource) { described_class.new }
  let(:adapter)      { Valkyrie::Persistence::Memory::MetadataAdapter.new }

  it_behaves_like 'a Hyrax::Resource'

  # Hyrax::Resource was loading earlier than the `allow(Hyrax.config).to receive(:flexible?)` line,
  # so we remove it and load it again in order for the allow to take effect
  def load_resource_model
    Hyrax.send(:remove_const, :Resource) if defined?(Hyrax::Resource)
    load Hyrax::Engine.root.join('app', 'models', 'hyrax', 'resource.rb')
  end

  before { load_resource_model }

  context 'when using flexible metadata' do
    it 'includes the Hyrax::Flexibility module' do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      load_resource_model

      expect(Hyrax::Resource.included_modules).to include(Hyrax::Flexibility)
    end
  end

  context 'when not using flexible metadata' do
    it 'does not include the Hyrax::Flexibility module' do
      allow(Hyrax.config).to receive(:flexible?).and_return(false)

      expect(Hyrax::Resource.included_modules).not_to include(Hyrax::Flexibility)
    end
  end

  describe '#events' do
    it 'includes Hyrax::WithEvents' do
      expect(resource).to respond_to(:events)
    end
  end

  describe '#embargo' do
    subject(:resource) { described_class.new(embargo: embargo) }
    let(:embargo)      { FactoryBot.create(:hyrax_embargo) }

    it 'saves the embargo id' do
      # load_resource_model
      resource.embargo = Hyrax.persister.save(resource: embargo)

      expect(Hyrax.persister.save(resource: resource).embargo)
        .to have_attributes(embargo_release_date: embargo.embargo_release_date)
    end
  end

  describe '#lease' do
    subject(:resource) { described_class.new(lease: lease) }
    let(:lease)        { FactoryBot.build(:hyrax_lease) }

    it 'saves the lease id' do
      # load_resource_model
      resource.lease = Hyrax.persister.save(resource: lease)

      expect(Hyrax.persister.save(resource: resource).lease)
        .to have_attributes(lease_expiration_date: lease.lease_expiration_date)
    end
  end

  describe '#visibility' do
    let(:open) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

    it 'round trips' do
      expect { resource.visibility = open }
        .to change { resource.visibility }
        .to open
    end

    context 'when setting to public' do
      it 'adds public read group' do
        expect { resource.visibility = open }
          .to change { resource.read_groups }
          .to contain_exactly(Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC)
      end
    end

    context 'when setting to unknown visibility' do
      it 'raises a useful error' do
        expect { resource.visibility = "oops" }.to raise_error KeyError
      end
    end
  end
end
