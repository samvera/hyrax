# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::CompoundValidator do
  subject(:validator) { described_class.new(profile: profile, errors: errors) }
  let(:errors) { [] }

  def t(key, **opts)
    I18n.t("hyrax.flexible_schema_validators.compound_validator.errors.#{key}", **opts)
  end

  # A subproperty declares membership via `available_on: { properties: [...] }`.
  def member_of(*parents)
    { 'available_on' => { 'properties' => parents } }
  end

  describe '#validate!' do
    context 'with a well-formed compound (parent + flat subproperties)' do
      let(:profile) do
        {
          'properties' => {
            'participants' => { 'type' => 'hash' },
            'participant_title' => { 'type' => 'string', **member_of('participants') },
            'participant_name' => { 'type' => 'string', **member_of('participants'), 'indexing' => %w[participant_name_tesim] },
            'participant_role' => { 'type' => 'controlled', **member_of('participants'),
                                    'values' => %w[Author Editor], 'indexing' => %w[participant_role_sim] }
          }
        }
      end

      it 'records no errors' do
        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'with a controlled subproperty that uses an authority instead of inline values' do
      let(:profile) do
        {
          'properties' => {
            'participants' => { 'type' => 'hash' },
            'participant_role' => { 'type' => 'controlled', **member_of('participants'), 'authority' => 'participant_role' }
          }
        }
      end

      it 'is valid (authority satisfies the option-source requirement)' do
        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'with a controlled subproperty that declares neither authority nor values' do
      let(:profile) do
        {
          'properties' => {
            'participants' => { 'type' => 'hash' },
            'participant_role' => { 'type' => 'controlled', **member_of('participants') }
          }
        }
      end

      it 'records an error keyed on the subproperty' do
        validator.validate!
        expect(errors).to include(t('controlled_without_source', property: 'participant_role'))
      end
    end

    context 'with a top-level indexing declaration on the compound parent' do
      let(:profile) do
        {
          'properties' => {
            'participants' => { 'type' => 'hash', 'indexing' => %w[participants_tesim] },
            'participant_name' => { 'type' => 'string', **member_of('participants') }
          }
        }
      end

      it 'records an error that indexing belongs on subproperties' do
        validator.validate!
        expect(errors).to include(t('top_level_indexing', property: 'participants'))
      end
    end

    context 'with a subproperty whose parent is not a declared type: hash compound' do
      let(:profile) do
        {
          'properties' => {
            # parent missing entirely
            'participant_name' => { 'type' => 'string', **member_of('participants') },
            # parent exists but is not a hash
            'note' => { 'type' => 'string' },
            'note_detail' => { 'type' => 'string', **member_of('note') }
          }
        }
      end

      it 'records an unknown_parent error for each' do
        validator.validate!
        expect(errors).to include(t('unknown_parent', property: 'participant_name', parent: 'participants'))
        expect(errors).to include(t('unknown_parent', property: 'note_detail', parent: 'note'))
      end
    end

    context 'with a hash property that is not a compound (no subproperties, e.g. redirects)' do
      let(:profile) do
        { 'properties' => { 'redirects' => { 'type' => 'hash' } } }
      end

      it 'ignores it (not a compound)' do
        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'with no compound properties at all' do
      let(:profile) { { 'properties' => { 'title' => { 'type' => 'string' } } } }

      it 'is silent' do
        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'with a subproperty shared by two compound parents' do
      let(:profile) do
        {
          'properties' => {
            'participants' => { 'type' => 'hash' },
            'contributors' => { 'type' => 'hash' },
            # one definition, named into both compounds, aliased to `title` inside each
            'shared_title' => { 'type' => 'string', 'name' => 'title',
                                **member_of('participants', 'contributors') }
          }
        }
      end

      it 'is valid (a member may name more than one parent)' do
        validator.validate!
        expect(errors).to be_empty
      end
    end

    context 'with a subproperty naming one valid and one invalid parent' do
      let(:profile) do
        {
          'properties' => {
            'participants' => { 'type' => 'hash' },
            'shared_title' => { 'type' => 'string', **member_of('participants', 'nonexistent') }
          }
        }
      end

      it 'records unknown_parent only for the invalid parent' do
        validator.validate!
        expect(errors).to include(t('unknown_parent', property: 'shared_title', parent: 'nonexistent'))
        expect(errors).not_to include(t('unknown_parent', property: 'shared_title', parent: 'participants'))
      end
    end

    context 'with two sub-properties resolving to the same in-compound name in one compound' do
      # The exact collision that silently dropped a definition: a per-compound
      # `participant_title` and a reused `shared_title` both alias `name: title`
      # under `participants`.
      let(:profile) do
        {
          'properties' => {
            'participants' => { 'type' => 'hash' },
            'relationships' => { 'type' => 'hash' },
            'participant_title' => { 'type' => 'string', 'name' => 'title', **member_of('participants') },
            'shared_title' => { 'type' => 'string', 'name' => 'title',
                                **member_of('participants', 'relationships') }
          }
        }
      end

      it 'records a duplicate-name error naming the compound and the colliding keys' do
        validator.validate!
        expect(errors).to include(
          t('duplicate_subproperty_name', parent: 'participants', name: 'title',
                                          properties: 'participant_title, shared_title')
        )
      end

      it 'does not flag the same name when it lands in different compounds' do
        # `shared_title` resolves to `title` in both participants and relationships,
        # but relationships has no other `title`, so no collision there.
        validator.validate!
        expect(errors).not_to include(
          t('duplicate_subproperty_name', parent: 'relationships', name: 'title',
                                          properties: a_string_including('shared_title'))
        )
      end
    end

    context 'with distinct in-compound names (no collision)' do
      let(:profile) do
        {
          'properties' => {
            'participants' => { 'type' => 'hash' },
            'participant_name' => { 'type' => 'string', 'name' => 'name', **member_of('participants') },
            'participant_role' => { 'type' => 'string', 'name' => 'role', **member_of('participants') }
          }
        }
      end

      it 'records no duplicate-name error' do
        validator.validate!
        expect(errors).to be_empty
      end
    end
  end
end
