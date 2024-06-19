# frozen_string_literal: true

require 'hyrax/specs/shared_specs/hydra_works'
require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::Resource do
  subject(:resource) { described_class.new }
  let(:adapter)      { Valkyrie::Persistence::Memory::MetadataAdapter.new }

  it_behaves_like 'a Hyrax::Resource'

  describe '#events' do
    it 'includes Hyrax::WithEvents' do
      expect(resource).to respond_to(:events)
    end
  end

  describe '#embargo' do
    subject(:resource) { described_class.new(embargo: embargo) }
    let(:embargo)      { FactoryBot.create(:hyrax_embargo) }

    it 'saves the embargo id' do
      resource.embargo = Hyrax.persister.save(resource: embargo)

      expect(Hyrax.persister.save(resource: resource).embargo)
        .to have_attributes(embargo_release_date: embargo.embargo_release_date)
    end
  end

  describe '#lease' do
    subject(:resource) { described_class.new(lease: lease) }
    let(:lease)        { FactoryBot.build(:hyrax_lease) }

    it 'saves the lease id' do
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
