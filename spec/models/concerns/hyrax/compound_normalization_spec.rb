# frozen_string_literal: true

RSpec.describe Hyrax::CompoundNormalization do
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      def self.name
        'TestNormalizedCompoundResource'
      end

      attribute :contributors,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: { 'given_name' => { 'type' => 'string' } }
                )

      include Hyrax::CompoundNormalization
    end
  end

  describe '.compound_attribute_names' do
    it 'derives the compound list from the schema' do
      expect(resource_class.compound_attribute_names).to contain_exactly(:contributors)
    end
  end

  describe 'read-path normalization' do
    it 'collapses a multi-key splayed pair array back into a hash' do
      # This is the shape JSONValueMapper produces on reload of a single entry:
      # the persisted [{given_name:, family:}] is unwrapped and splayed to pairs.
      expect(Hyrax::CompoundNormalization.normalize_compound([[:given_name, 'Ada'], [:family, 'Lovelace']]))
        .to eq([{ 'given_name' => 'Ada', 'family' => 'Lovelace' }])
    end

    it 'rebuilds one entry per pair when a key repeats (several one-field entries)' do
      # JSONValueMapper also unwraps each one-key hash in a multi-entry value
      # to its [key, value] pair, so a persisted [{name: A}, {name: B}] arrives
      # as pairs too. A repeated key can only mean separate entries - one
      # splayed entry never repeats a key - so do not merge them into one hash
      # (that silently keeps only the last value).
      expect(Hyrax::CompoundNormalization.normalize_compound([[:name, 'A'], [:name, 'B']]))
        .to eq([{ 'name' => 'A' }, { 'name' => 'B' }])
    end

    it 'leaves a well-formed array of hashes unchanged (stringifying keys)' do
      expect(Hyrax::CompoundNormalization.normalize_compound([{ given_name: 'Ada' }]))
        .to eq([{ 'given_name' => 'Ada' }])
    end

    it 'returns nil unchanged' do
      expect(Hyrax::CompoundNormalization.normalize_compound(nil)).to be_nil
    end

    it 'wraps a single hash in an array' do
      expect(Hyrax::CompoundNormalization.normalize_compound({ 'given_name' => 'Ada' }))
        .to eq([{ 'given_name' => 'Ada' }])
    end
  end

  # These pin behavior that is a deliberate consequence of an information limit,
  # not an accident: by the time Valkyrie's EnumeratorValue has unwrapped single-key
  # hashes, some origins are indistinguishable here. Changing any of these is a
  # behavior change, not a cleanup - the comments say why each reading was chosen.
  describe 'information-limited disambiguation (load-bearing choices)' do
    it 'reads distinct-key pairs as ONE multi-field entry, not several one-field entries' do
      # [[:name, A], [:role, R]] is genuinely ambiguous once unwrapped: it could be
      # one entry {name:, role:} splayed apart, or two one-field entries with
      # different keys. Only the repeated-key case is decidable; with distinct keys
      # we keep the single-entry reading (the common shape, and the non-lossy
      # default). Do not "fix" this to split - the signal to do so does not survive
      # Valkyrie's read path; that would require a Valkyrie-layer change.
      expect(Hyrax::CompoundNormalization.normalize_compound([[:name, 'Ada'], [:role, 'Author']]))
        .to eq([{ 'name' => 'Ada', 'role' => 'Author' }])
    end

    it 'splits correctly when two pairs share a key and a third is distinct' do
      # The repeated key (:name) proves these are separate entries, so every pair
      # becomes its own one-field entry - including the distinct :role pair.
      expect(Hyrax::CompoundNormalization.normalize_compound([[:name, 'A'], [:name, 'B'], [:role, 'X']]))
        .to eq([{ 'name' => 'A' }, { 'name' => 'B' }, { 'role' => 'X' }])
    end

    it 'leaves a flat pair whose value is non-scalar untouched (conservative guard)' do
      # collapse_flat_pair only rebuilds a one-field entry when the value is a
      # scalar - the only shape a real compound subproperty produces. A value that
      # is an Array or Hash is not a recognizable splayed entry, so it is left for
      # schema coercion to accept or reject loudly, rather than silently mangled
      # into a fabricated entry.
      expect(Hyrax::CompoundNormalization.normalize_compound([:aliases, %w[x y]]))
        .to eq([:aliases, %w[x y]])
      expect(Hyrax::CompoundNormalization.normalize_compound([:meta, { 'k' => 'v' }]))
        .to eq([:meta, { 'k' => 'v' }])
    end
  end

  describe 'round-trip through the class constructor' do
    it 'normalizes splayed compound input passed to .new' do
      resource = resource_class.new(contributors: [[:given_name, 'Ada']])
      expect(resource.contributors).to eq([{ 'given_name' => 'Ada' }])
    end

    it 'normalizes well-formed compound input passed to .new' do
      resource = resource_class.new(contributors: [{ 'given_name' => 'Grace' }])
      expect(resource.contributors).to eq([{ 'given_name' => 'Grace' }])
    end
  end
end
