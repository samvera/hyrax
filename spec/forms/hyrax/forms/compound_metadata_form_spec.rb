# frozen_string_literal: true

# Integration spec for the compound-metadata form flow through the real
# Hyrax::Forms::ResourceForm pipeline (factory build -> validate -> sync).
#
# These assertions exercise the wiring that unit specs for the populator and
# helper can't see:
#   * the `<compound>` reader is registered (so the form partial can render),
#   * the virtual `<compound>_attributes` populator is registered *in Reform's
#     schema* (so `validate` invokes it — registering it too late silently
#     drops the value), and
#   * `validate` + `sync` actually writes the compound onto the model.
#
# It mirrors the existing redirects coverage in resource_form_spec.rb, which
# documents the same "Reform drops the assigned value during sync without a
# class-level FormFields include" failure mode.
#
# This is a non-flexible-mode integration spec: it includes the compound schema
# on the model class via `Hyrax::Schema(:compound_metadata)` (the
# `HYRAX_FLEXIBLE=false` registration path) and stubs `flexible? => false`. When
# the host app boots in flexible mode (allinson), the model class composition is
# fixed at load time and the stub can't retroactively attach the schema, so this
# path can only be exercised under a non-flexible stack (dassie/koppie). The flex
# path is covered by the singleton-schema registration in
# compound_field_behavior_spec and the live allinson UI.
RSpec.describe 'Compound metadata form flow', type: :model, unless: Hyrax.config.flexible? do
  before do
    allow(Hyrax.config).to receive(:compound_metadata_enabled?).and_return(true)
    allow(Hyrax.config).to receive(:flexible?).and_return(false)
    # A work-like resource that includes the shipped compound schema, the way
    # Hyrax::Work does. Named so the form factory's `*Form` lookup falls back
    # to the generic ResourceForm.
    stub_const('CompoundTestWork', Class.new(Hyrax::Work) do
      include Hyrax::Schema(:compound_metadata)
      include Hyrax::CompoundNormalization
    end)
  end

  let(:resource) { CompoundTestWork.new }
  let(:form) { Hyrax::Forms::ResourceForm.for(resource: resource) }

  describe 'property registration' do
    it 'exposes the compound readers so the form partial can render existing rows' do
      expect(form).to respond_to(:agent)
      expect(form).to respond_to(:identifiers)
    end

    it 'exposes the virtual `<compound>_attributes` setters for nested form params' do
      expect(form).to respond_to(:agent_attributes=)
      expect(form).to respond_to(:identifiers_attributes=)
    end

    it 'lists the compounds as compound_terms (and keeps them out of primary/secondary terms)' do
      expect(form.compound_terms).to include(:agent, :identifiers, :compound_rights)
      expect(form.primary_terms).not_to include(:agent, :identifiers, :compound_rights)
      expect(form.secondary_terms).not_to include(:agent, :identifiers, :compound_rights)
    end

    it 'registers `agent_attributes` as a real Reform property (not just method-missing)' do
      # This is the property that has to exist in Reform's schema *before*
      # validate runs; if it is registered too late the populator never fires.
      # In non-flexible mode it is registered on the form class via FormFields;
      # check the class definitions registry (the same lens the redirects
      # coverage uses).
      definition_keys = form.class.definitions.keys.map(&:to_s)
      expect(definition_keys).to include('agent_attributes')
    end
  end

  describe 'validate + sync writes the compound to the model' do
    let(:params) do
      { 'agent_attributes' =>
          { '0' => { 'title' => 'Dr', 'agent_name' => 'Ada Lovelace', 'agent_role' => 'Author' } },
        'identifiers_attributes' =>
          { '0' => { 'identifier' => '10.1234/x', 'identifier_type' => 'DOI' } } }
    end

    it 'populates the compound on the form during validate' do
      form.validate(params)
      expect(form.agent)
        .to eq([{ 'title' => 'Dr', 'agent_name' => 'Ada Lovelace', 'agent_role' => 'Author' }])
      expect(form.identifiers)
        .to eq([{ 'identifier' => '10.1234/x', 'identifier_type' => 'DOI' }])
    end

    it 'writes the compound through to the model on sync' do
      form.validate(params)
      form.sync
      expect(form.model.agent)
        .to eq([{ 'title' => 'Dr', 'agent_name' => 'Ada Lovelace', 'agent_role' => 'Author' }])
      expect(form.model.identifiers)
        .to eq([{ 'identifier' => '10.1234/x', 'identifier_type' => 'DOI' }])
    end

    it 'drops `_destroy` and all-blank rows' do
      form.validate('agent_attributes' =>
        { '0' => { 'agent_name' => 'Keep', 'agent_role' => 'Author' },
          '1' => { 'agent_name' => 'Remove', '_destroy' => 'true' },
          '2' => { 'title' => '', 'agent_name' => '', 'agent_role' => '' } })
      form.sync
      expect(form.model.agent).to eq([{ 'title' => nil, 'agent_name' => 'Keep', 'agent_role' => 'Author' }])
    end
  end

  describe 'persistence round-trip', :active_fedora do
    # Skips on the Fedora adapter, which cannot serialize plain-hash compounds
    # to RDF; the compound feature targets the Valkyrie/Postgres path.
    it 'round-trips the compound through the persister' do
      skip 'requires a Valkyrie (non-Fedora) persister' if
        Hyrax.persister.is_a?(Wings::Valkyrie::Persister)

      form.validate('agent_attributes' =>
        { '0' => { 'agent_name' => 'Grace Hopper', 'agent_role' => 'Editor' } })
      form.sync
      saved = Hyrax.persister.save(resource: form.model)
      reloaded = Hyrax.query_service.find_by(id: saved.id)

      expect(reloaded.agent.first['agent_name'] || reloaded.agent.first[:agent_name])
        .to eq('Grace Hopper')
    end
  end
end
