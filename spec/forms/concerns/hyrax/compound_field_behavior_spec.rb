# frozen_string_literal: true

RSpec.describe Hyrax::CompoundFieldBehavior do
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      def self.name
        'TestCompoundResource'
      end

      attribute :contributors,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: {
                    'given_name' => { 'type' => 'string' },
                    'family_name' => { 'type' => 'string' }
                  }
                )

      # A second compound with a `multiple: true` controlled member, kept
      # separate from `contributors` so the single-value examples above are
      # unaffected by the extra sub-property.
      attribute :credits,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: {
                    'name' => { 'type' => 'string' },
                    'role' => { 'type' => 'controlled', 'form' => { 'multiple' => true } }
                  }
                )
    end
  end

  let(:model) { resource_class.new }

  # A minimal form stand-in that includes the behavior and exposes the model
  # and a settable compound accessor, mirroring the redirects behavior spec.
  let(:form_class) do
    Class.new do
      attr_accessor :contributors, :credits

      def self.property(*); end

      def initialize(model)
        @model = model
      end

      attr_reader :model

      def respond_to_missing?(name, *)
        %i[contributors contributors= credits credits=].include?(name) || super
      end

      def from_hash(params)
        params
      end

      def deserialize!(params)
        from_hash(params)
      end

      # Prepend (not include) so the module's `deserialize!` lands above the
      # class's own on the ancestor chain — mirroring how
      # `Hyrax::Forms::ResourceForm.inherited` wires the behavior.
      prepend Hyrax::CompoundFieldBehavior
    end
  end

  subject(:form) { form_class.new(model) }

  describe '#compound_attributes_populator' do
    it 'builds plain string-keyed hashes with only declared sub-properties' do
      fragment = {
        '0' => { 'given_name' => 'Ada', 'family_name' => 'Lovelace', 'unknown' => 'drop me' },
        '1' => { 'given_name' => 'Alan', 'family_name' => 'Turing' }
      }
      form.send(:compound_attributes_populator, fragment: fragment, as: :contributors_attributes)

      expect(form.contributors).to eq([
                                        { 'given_name' => 'Ada', 'family_name' => 'Lovelace' },
                                        { 'given_name' => 'Alan', 'family_name' => 'Turing' }
                                      ])
    end

    it 'drops rows marked for destruction' do
      fragment = {
        '0' => { 'given_name' => 'Ada', 'family_name' => 'Lovelace' },
        '1' => { 'given_name' => 'Gone', 'family_name' => 'Away', '_destroy' => 'true' }
      }
      form.send(:compound_attributes_populator, fragment: fragment, as: :contributors_attributes)

      expect(form.contributors).to eq([{ 'given_name' => 'Ada', 'family_name' => 'Lovelace' }])
    end

    it 'drops the always-submitted marker and all-blank rows' do
      fragment = {
        '_marker' => { '_destroy' => '1' },
        '0' => { 'given_name' => '', 'family_name' => '  ' },
        '1' => { 'given_name' => 'Grace', 'family_name' => 'Hopper' }
      }
      form.send(:compound_attributes_populator, fragment: fragment, as: :contributors_attributes)

      expect(form.contributors).to eq([{ 'given_name' => 'Grace', 'family_name' => 'Hopper' }])
    end

    context 'with a multiple: true sub-property' do
      it 'fans a row with several selected values out into one entry per value' do
        fragment = { '0' => { 'name' => 'Ada', 'role' => %w[author editor] } }
        form.send(:compound_attributes_populator, fragment: fragment, as: :credits_attributes)

        expect(form.credits).to eq([
                                     { 'name' => 'Ada', 'role' => 'author' },
                                     { 'name' => 'Ada', 'role' => 'editor' }
                                   ])
      end

      it 'collapses a single selected value to one scalar entry' do
        fragment = { '0' => { 'name' => 'Ada', 'role' => ['author'] } }
        form.send(:compound_attributes_populator, fragment: fragment, as: :credits_attributes)

        expect(form.credits).to eq([{ 'name' => 'Ada', 'role' => 'author' }])
      end

      it 'keeps a row with only the multi member blank as one scalar-nil entry' do
        fragment = { '0' => { 'name' => 'Ada', 'role' => [''] } }
        form.send(:compound_attributes_populator, fragment: fragment, as: :credits_attributes)

        expect(form.credits).to eq([{ 'name' => 'Ada', 'role' => nil }])
      end

      it 'drops a row where every member (including the multi) is blank' do
        fragment = { '0' => { 'name' => '', 'role' => ['', ''] } }
        form.send(:compound_attributes_populator, fragment: fragment, as: :credits_attributes)

        expect(form.credits).to eq([])
      end
    end

    it 'orders rows by their numeric key' do
      fragment = {
        '2' => { 'given_name' => 'Third' },
        '0' => { 'given_name' => 'First' },
        '1' => { 'given_name' => 'Second' }
      }
      form.send(:compound_attributes_populator, fragment: fragment, as: :contributors_attributes)

      expect(form.contributors.map { |r| r['given_name'] }).to eq(%w[First Second Third])
    end
  end

  describe '#deserialize!' do
    it 'strips the renamed bare compound key so the populator owns the write' do
      result = form.deserialize!('contributors' => [{ 'given_name' => 'leaked' }], 'other' => 'keep')
      expect(result).to eq('other' => 'keep')
    end
  end
end
