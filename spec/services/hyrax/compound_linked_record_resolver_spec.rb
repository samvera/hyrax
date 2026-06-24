# frozen_string_literal: true

# The registry/resolver for the `linked_record` compound sub-property type. A
# `linked_record` value is a reference to a row in a database table; the resolver
# turns that stored id into a display label and a show path, the database-backed
# analogue of {Hyrax::CompoundWorkResolver} (which resolves work ids via Solr).
#
# Generic by design: a source registers a finder, a label proc, a path proc, an
# optional search proc (for the picker autocomplete), and an optional create proc
# (for inline lookup-or-create). The resolver stays naive about which tables
# exist.
RSpec.describe Hyrax::CompoundLinkedRecordResolver do
  let(:record) { Struct.new(:id, :name).new(7, 'Ada Lovelace') }
  let(:store) { {} }

  around do |example|
    described_class.register(
      :stub_people,
      finder: ->(id) { id.to_s == '7' ? record : store[id.to_s] },
      label: ->(r) { r.name },
      path: ->(r) { "/stub_people/#{r.id}" },
      search: lambda { |q|
        ([record] + store.values)
          .select { |r| r.name.to_s.downcase.include?(q.to_s.downcase) }
          .map { |r| { id: r.id.to_s, label: r.name, value: r.id.to_s } }
      },
      create: lambda { |attrs|
        rec = Struct.new(:id, :name, :display_name, :errors).new(
          (store.size + 100).to_s, attrs[:display_name], attrs[:display_name], []
        )
        store[rec.id] = rec
        rec
      }
    )
    example.run
  ensure
    described_class.registry.delete(:stub_people)
  end

  describe '.resolve' do
    it 'returns [label, path] for a found record' do
      expect(described_class.resolve(:stub_people, '7')).to eq(['Ada Lovelace', '/stub_people/7'])
    end

    it 'returns nil when the record is not found' do
      expect(described_class.resolve(:stub_people, '999')).to be_nil
    end

    it 'returns nil for an unregistered source' do
      expect(described_class.resolve(:nope, '7')).to be_nil
    end
  end

  describe '.label_for' do
    it 'returns the label for a found record' do
      expect(described_class.label_for(:stub_people, '7')).to eq('Ada Lovelace')
    end

    it 'falls back to the id string when not found' do
      expect(described_class.label_for(:stub_people, '999')).to eq('999')
    end

    context 'with a label_field naming a record attribute' do
      let(:record) { Struct.new(:id, :name, :display_name).new(7, 'PROC NAME', 'Ada Lovelace') }

      it 'reads the label_field off the record in preference to the label proc' do
        expect(described_class.label_for(:stub_people, '7', label_field: 'display_name'))
          .to eq('Ada Lovelace')
      end

      it 'falls back to the label proc when the field is blank/absent' do
        expect(described_class.label_for(:stub_people, '7', label_field: 'nope'))
          .to eq('PROC NAME')
      end
    end
  end

  describe '.path_for' do
    it 'returns the path for a found record' do
      expect(described_class.path_for(:stub_people, '7')).to eq('/stub_people/7')
    end

    it 'returns nil when not found' do
      expect(described_class.path_for(:stub_people, '999')).to be_nil
    end
  end

  describe '.title_and_path' do
    it 'returns label + path when found' do
      expect(described_class.title_and_path(:stub_people, '7')).to eq(['Ada Lovelace', '/stub_people/7'])
    end

    it 'falls back to [id, nil] when not found' do
      expect(described_class.title_and_path(:stub_people, '999')).to eq(['999', nil])
    end
  end

  describe '.find' do
    it 'returns the raw record so callers can read fields beyond label/path' do
      expect(described_class.find(:stub_people, '7')).to eq(record)
    end

    it 'returns nil for an unregistered source or blank id' do
      expect(described_class.find(:nope, '7')).to be_nil
      expect(described_class.find(:stub_people, '')).to be_nil
    end
  end

  describe '.search' do
    it 'returns picker results from the source search proc' do
      results = described_class.search(:stub_people, 'ada')
      expect(results).to contain_exactly(a_hash_including(id: '7', label: 'Ada Lovelace'))
    end

    it 'returns [] for a source registered without a search proc' do
      described_class.register(:searchless, finder: ->(_id) {}, label: ->(_r) {}, path: ->(_r) {})
      expect(described_class.search(:searchless, 'x')).to eq([])
    ensure
      described_class.registry.delete(:searchless)
    end

    it 'returns [] for an unregistered source' do
      expect(described_class.search(:nope, 'x')).to eq([])
    end
  end

  describe '.searchable? and .creatable?' do
    it 'reports the optional capabilities a source declares' do
      expect(described_class.searchable?(:stub_people)).to be(true)
      expect(described_class.creatable?(:stub_people)).to be(true)
      expect(described_class.creatable?(:nope)).to be(false)
    end
  end

  describe '.create' do
    it 'creates a record via the source, resolvable through the same source' do
      created = described_class.create(:stub_people, display_name: 'Grace Hopper')
      expect(created).not_to be_nil
      expect(described_class.label_for(:stub_people, created.id)).to eq('Grace Hopper')
      expect(described_class.path_for(:stub_people, created.id)).to eq("/stub_people/#{created.id}")
    end

    it 'returns nil for an unregistered or non-creatable source' do
      expect(described_class.create(:nope, display_name: 'X')).to be_nil
    end
  end

  # A misconfigured profile (or the default schema) can leave a linked_record
  # sub-property with no `authority:`, so the lookups receive a nil/blank source.
  # These must degrade gracefully rather than raise NoMethodError on `nil.to_sym`.
  describe 'with a nil or blank source' do
    it 'reports not searchable / not creatable' do
      expect(described_class.searchable?(nil)).to be(false)
      expect(described_class.creatable?('')).to be(false)
    end

    it 'returns safe empties from search/create' do
      expect(described_class.search(nil, 'q')).to eq([])
      expect(described_class.create('', display_name: 'X')).to be_nil
    end

    it 'falls back to the id string / nils for label and path lookups' do
      expect(described_class.label_for(nil, '7')).to eq('7')
      expect(described_class.path_for('', '7')).to be_nil
      expect(described_class.title_and_path(nil, '7')).to eq(['7', nil])
      expect(described_class.find(nil, '7')).to be_nil
    end
  end
end
