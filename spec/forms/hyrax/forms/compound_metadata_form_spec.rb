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
      expect(form).to respond_to(:participants)
      expect(form).to respond_to(:identifiers)
    end

    it 'exposes the virtual `<compound>_attributes` setters for nested form params' do
      expect(form).to respond_to(:participants_attributes=)
      expect(form).to respond_to(:identifiers_attributes=)
    end

    it 'lists the compounds as compound_terms (and keeps them out of primary/secondary terms)' do
      expect(form.compound_terms).to include(:participants, :identifiers, :compound_rights)
      expect(form.primary_terms).not_to include(:participants, :identifiers, :compound_rights)
      expect(form.secondary_terms).not_to include(:participants, :identifiers, :compound_rights)
    end

    it 'partitions compounds by their form: { primary: } flag' do
      # The shipped samples declare `participants` and `relationships` primary;
      # `identifiers` and `compound_rights` are non-primary ("Additional fields").
      expect(form.primary_compound_terms).to contain_exactly(:participants, :relationships)
      expect(form.secondary_compound_terms).to contain_exactly(:identifiers, :compound_rights)
      expect(form.display_additional_fields?).to be true
    end

    it 'registers `participants_attributes` as a real Reform property (not just method-missing)' do
      # This is the property that has to exist in Reform's schema *before*
      # validate runs; if it is registered too late the populator never fires.
      # In non-flexible mode it is registered on the form class via FormFields;
      # check the class definitions registry (the same lens the redirects
      # coverage uses).
      definition_keys = form.class.definitions.keys.map(&:to_s)
      expect(definition_keys).to include('participants_attributes')
    end
  end

  describe 'validate + sync writes the compound to the model' do
    let(:params) do
      { 'participants_attributes' =>
          { '0' => { 'participant_title' => 'Dr', 'participant_name' => 'Ada Lovelace', 'participant_role' => 'Author' } },
        'identifiers_attributes' =>
          { '0' => { 'identifier_value' => '10.1234/x', 'identifier_type' => 'DOI' } } }
    end

    it 'populates the compound on the form during validate' do
      form.validate(params)
      expect(form.participants)
        .to eq([{ 'participant_title' => 'Dr', 'participant_name' => 'Ada Lovelace', 'participant_role' => 'Author' }])
      expect(form.identifiers)
        .to eq([{ 'identifier_value' => '10.1234/x', 'identifier_type' => 'DOI' }])
    end

    it 'writes the compound through to the model on sync' do
      form.validate(params)
      form.sync
      expect(form.model.participants)
        .to eq([{ 'participant_title' => 'Dr', 'participant_name' => 'Ada Lovelace', 'participant_role' => 'Author' }])
      expect(form.model.identifiers)
        .to eq([{ 'identifier_value' => '10.1234/x', 'identifier_type' => 'DOI' }])
    end

    it 'drops `_destroy` and all-blank rows' do
      form.validate('participants_attributes' =>
        { '0' => { 'participant_name' => 'Keep', 'participant_role' => 'Author' },
          '1' => { 'participant_name' => 'Remove', '_destroy' => 'true' },
          '2' => { 'participant_title' => '', 'participant_name' => '', 'participant_role' => '' } })
      form.sync
      expect(form.model.participants).to eq([{ 'participant_title' => nil, 'participant_name' => 'Keep', 'participant_role' => 'Author' }])
    end
  end

  describe 'required-subproperty validation blocks save' do
    # Exercises the real form + Hyrax::CompoundEntryValidator end to end against
    # the *shipped* compound schema (no stub). The shipped samples require
    # sub-properties within a row (e.g. participants needs participant_name + participant_role,
    # relationships needs related_item + relationship_type) but none is required
    # at the compound level, so an empty compound is valid. Asserting through the
    # real schema is what catches a validator that reads the form wrapper instead
    # of `form.model`.
    #
    # Compound errors are attached to :base with the compound named in the
    # message (so they render cleanly on both the work and collection forms).
    def base_errors(form)
      form.valid?
      form.errors[:base]
    end

    it 'allows an empty compound (none is required at the compound level)' do
      form.validate('participants_attributes' => { '_marker' => { '_destroy' => '1' } })
      expect(base_errors(form)).to be_empty
    end

    it 'flags a participants row that omits a required sub-property' do
      form.validate('participants_attributes' => { '0' => { 'participant_role' => 'Author' } })
      expect(base_errors(form)).to include(a_string_including('Participants'))
    end

    it 'flags a relationships row that omits a required sub-property' do
      form.validate('relationships_attributes' => { '0' => { 'relationship_type' => 'References' } })
      expect(base_errors(form)).to include(a_string_including('Relationships'))
    end

    it 'does not flag participants when its required sub-properties are filled' do
      form.validate('participants_attributes' => { '0' => { 'participant_name' => 'Ada', 'participant_role' => 'Author' } })
      expect(base_errors(form)).not_to include(a_string_including('Participants'))
    end

    it 'never flags `compound_rights` (no required sub-properties)' do
      form.validate('participants_attributes' => { '0' => { 'participant_name' => 'Ada', 'participant_role' => 'Author' } })
      expect(base_errors(form)).not_to include(a_string_including('Rights'))
    end
  end

  describe 'persistence round-trip', :active_fedora do
    # Skips on the Fedora adapter, which cannot serialize plain-hash compounds
    # to RDF; the compound feature targets the Valkyrie/Postgres path.
    it 'round-trips the compound through the persister' do
      skip 'requires a Valkyrie (non-Fedora) persister' if
        Hyrax.persister.is_a?(Wings::Valkyrie::Persister)

      form.validate('participants_attributes' =>
        { '0' => { 'participant_name' => 'Grace Hopper', 'participant_role' => 'Editor' } })
      form.sync
      saved = Hyrax.persister.save(resource: form.model)
      reloaded = Hyrax.query_service.find_by(id: saved.id)

      expect(reloaded.participants.first['participant_name'] || reloaded.participants.first[:participant_name])
        .to eq('Grace Hopper')
    end
  end
end
