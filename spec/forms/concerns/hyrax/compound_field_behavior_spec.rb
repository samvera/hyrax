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
    end
  end

  let(:model) { resource_class.new }

  # A minimal form stand-in that includes the behavior and exposes the model
  # and a settable compound accessor, mirroring the redirects behavior spec.
  let(:form_class) do
    Class.new do
      attr_accessor :contributors

      def self.property(*); end

      def initialize(model)
        @model = model
      end

      attr_reader :model

      def respond_to_missing?(name, *)
        %i[contributors contributors=].include?(name) || super
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
