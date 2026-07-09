# frozen_string_literal: true
RSpec.describe Hyrax::AuthorityService do
  let(:authority_map) do
    [
      HashWithIndifferentAccess.new(term: 'Active Label', label: 'Active Label', id: 'active-id', active: true),
      HashWithIndifferentAccess.new(term: 'Inactive Label', label: 'Inactive Label', id: 'inactive-id', active: false),
      HashWithIndifferentAccess.new(label: 'Active No Term', id: 'active-no-term-id', active: true),
      HashWithIndifferentAccess.new(term: 'No Active Flag Term', label: 'No Active Flag Label', id: 'no-active-flag-id')
    ]
  end

  let(:service_authority) { FakeAuthority.new(authority_map) }

  # A minimal host that mimics the shape of a module-level authority
  # service (e.g. Hyrax::ResourceTypesService).
  let(:service) do
    fake_authority = service_authority
    Module.new.tap do |m|
      m.extend(described_class)
      m.define_singleton_method(:authority) { fake_authority }
    end
  end

  include_examples "a tolerant authority service"

  describe ".authority_name" do
    let(:service) do
      fake_authority = service_authority
      allow(Qa::Authorities::Local).to receive(:subauthority_for).with('fake-subauth').and_return(fake_authority)

      Module.new.tap do |m|
        m.extend(described_class)
        m.authority_name 'fake-subauth'
      end
    end

    it "defines `authority` that memoizes the Qa subauthority" do
      expect(service.authority).to eq service_authority
      expect(Qa::Authorities::Local).to have_received(:subauthority_for).with('fake-subauth').once
      expect(service.authority).to eq service_authority # second call still memoized
      expect(Qa::Authorities::Local).to have_received(:subauthority_for).with('fake-subauth').once
    end

    it "defines `authority=` for setting a replacement authority" do
      replacement = FakeAuthority.new([])
      service.authority = replacement
      expect(service.authority).to eq replacement
    end

    it "defines `select_all_options` as Array<[label, id]>" do
      expect(service.select_all_options)
        .to contain_exactly(['Active Label', 'active-id'],
                            ['Inactive Label', 'inactive-id'],
                            ['Active No Term', 'active-no-term-id'],
                            ['No Active Flag Label', 'no-active-flag-id'])
    end

    it "aliases `select_options` to `select_all_options`" do
      expect(service.select_options).to eq service.select_all_options
    end
  end

  describe ".microdata_namespace" do
    let(:service) do
      Module.new.tap do |m|
        m.extend(described_class)
        m.microdata_namespace 'fake_namespace.'
      end
    end

    it "looks up microdata using the configured namespace" do
      expect(Hyrax::Microdata).to receive(:fetch).with('fake_namespace.foo', default: Hyrax.config.microdata_default_type)
      service.microdata_type('foo')
    end

    it "returns the default microdata type when the id is nil" do
      expect(service.microdata_type(nil)).to eq Hyrax.config.microdata_default_type
    end
  end
end
