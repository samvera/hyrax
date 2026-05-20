# frozen_string_literal: true

RSpec.describe Hyrax::RedirectValidator do
  subject(:validator) { described_class.new(attributes: [:redirects]) }

  let(:record_class) do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :id, :redirects
      validates_with Hyrax::RedirectValidator, attributes: [:redirects]
    end
  end
  let(:record) do
    record_class.new.tap do |r|
      r.id = 'self-id'
      r.redirects = entries
    end
  end
  def entry(path:, display_url: false)
    { 'path' => path, 'display_url' => display_url }
  end
  let(:entries) { [] }

  before do
    allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
    allow(Hyrax::RedirectsLookup).to receive(:taken?).and_return(false)
  end

  describe '#validate_each' do
    context 'when the redirects feature is active' do
      let(:entries) { [entry(path: '/handle/12345/678', display_url: true)] }

      it 'is valid' do
        record.valid?
        expect(record.errors[:redirects]).to be_empty
      end
    end

    context 'when the redirects feature is inactive' do
      before { allow(Hyrax.config).to receive(:redirects_active?).and_return(false) }
      let(:entries) { [entry(path: 'no-leading-slash', display_url: false)] }

      it 'short-circuits without recording errors' do
        record.valid?
        expect(record.errors[:redirects]).to be_empty
      end
    end

    context 'when entries is blank' do
      let(:entries) { [] }

      it 'is valid' do
        record.valid?
        expect(record.errors[:redirects]).to be_empty
      end
    end

    context 'when the record does not support a redirects attribute' do
      let(:record_class) do
        Class.new do
          include ActiveModel::Validations
          attr_accessor :id
          validates_with Hyrax::RedirectValidator, attributes: [:redirects]
        end
      end
      let(:record) { record_class.new.tap { |r| r.id = 'self-id' } }

      it 'short-circuits without raising NoMethodError' do
        expect { record.valid? }.not_to raise_error
        expect(record.errors[:redirects]).to be_empty
      end
    end

    context 'when the record is a form wrapping a resource without :redirects' do
      let(:wrapped) { Struct.new(:id).new('wrapped-id') }
      let(:record) do
        klass = Class.new do
          include ActiveModel::Validations
          attr_accessor :id
          validates_with Hyrax::RedirectValidator, attributes: [:redirects]
          def initialize(target)
            @target = target
          end

          def __getobj__
            @target
          end

          def respond_to_missing?(_name, _priv = false)
            true
          end

          def method_missing(_name, *_args)
            nil
          end
        end
        klass.new(wrapped)
      end

      it 'unwraps the form and short-circuits when the underlying resource lacks :redirects' do
        expect { record.valid? }.not_to raise_error
      end
    end

    def t(key, **interp)
      I18n.t(key, scope: 'errors.messages.redirect', **interp)
    end

    context 'with a blank path' do
      let(:entries) { [entry(path: '', display_url: false)] }

      it 'records a blank-path error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:blank))
      end
    end

    context 'with a path missing a leading slash' do
      let(:entries) { [entry(path: 'handle/12345/678', display_url: false)] }

      it 'records a format error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:invalid_format, path: 'handle/12345/678'))
      end
    end

    context 'with whitespace in the path' do
      let(:entries) { [entry(path: '/has space', display_url: false)] }

      it 'records a format error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:invalid_format, path: '/has space'))
      end
    end

    context 'with a query string in the path' do
      let(:entries) { [entry(path: '/foo?bar=baz', display_url: false)] }

      it 'records a format error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:invalid_format, path: '/foo?bar=baz'))
      end
    end

    context 'with a path under a reserved Hyrax prefix' do
      let(:entries) { [entry(path: '/concern/generic_works/abc', display_url: false)] }

      it 'records a reserved-prefix error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:reserved_prefix, path: '/concern/generic_works/abc'))
      end
    end

    context 'with a path that exactly matches a reserved prefix' do
      let(:entries) { [entry(path: '/dashboard', display_url: false)] }

      it 'records a reserved-prefix error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:reserved_prefix, path: '/dashboard'))
      end
    end

    context 'with two entries sharing the same path on the same record' do
      let(:entries) do
        [
          entry(path: '/handle/1', display_url: false),
          entry(path: '/handle/1', display_url: false)
        ]
      end

      it 'records an intra-record duplicate error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:intra_record_duplicate, path: '/handle/1'))
      end
    end

    context 'with two entries that normalize to the same canonical path' do
      let(:entries) do
        [
          entry(path: '/handle/1', display_url: false),
          entry(path: '/handle/1/', display_url: false)
        ]
      end

      it 'records an intra-record duplicate error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:intra_record_duplicate, path: '/handle/1'))
      end
    end

    context 'with a reserved prefix typed with a trailing slash' do
      let(:entries) { [entry(path: '/dashboard/', display_url: false)] }

      it 'records a reserved-prefix error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:reserved_prefix, path: '/dashboard/'))
      end
    end

    context 'when the path is taken on another record' do
      let(:entries) { [entry(path: '/handle/12345/678', display_url: false)] }

      before do
        allow(Hyrax::RedirectsLookup)
          .to receive(:taken?)
          .with('/handle/12345/678', except_id: 'self-id')
          .and_return(true)
      end

      it 'records a global-uniqueness error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:already_taken, path: '/handle/12345/678'))
      end
    end

    context 'when a non-canonical form of the path is taken on another record' do
      let(:entries) { [entry(path: '/handle/12345/678/', display_url: false)] }

      before do
        allow(Hyrax::RedirectsLookup)
          .to receive(:taken?)
          .with('/handle/12345/678', except_id: 'self-id')
          .and_return(true)
      end

      it 'records a global-uniqueness error against the canonical path' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:already_taken, path: '/handle/12345/678/'))
      end
    end

    context 'when more than one entry is marked as the display URL' do
      let(:entries) do
        [
          entry(path: '/a', display_url: true),
          entry(path: '/b', display_url: true)
        ]
      end

      it 'records an at-most-one-display_url error' do
        record.valid?
        expect(record.errors[:redirects]).to include(t(:multiple_display_url))
      end
    end

    context 'when zero entries are marked as the display URL' do
      let(:entries) do
        [
          entry(path: '/a', display_url: false),
          entry(path: '/b', display_url: false)
        ]
      end

      it 'is valid (display_url is optional)' do
        record.valid?
        expect(record.errors[:redirects]).to be_empty
      end
    end
  end

  describe '#display_url_for' do
    it 'returns the stored false flag rather than nil' do
      expect(validator.send(:display_url_for, 'display_url' => false)).to be(false)
      expect(validator.send(:display_url_for, display_url: false)).to be(false)
    end

    it 'returns true when the flag is set' do
      expect(validator.send(:display_url_for, 'display_url' => true)).to be(true)
    end

    it 'returns nil when the flag is absent' do
      expect(validator.send(:display_url_for, 'path' => '/x')).to be_nil
    end
  end
end
