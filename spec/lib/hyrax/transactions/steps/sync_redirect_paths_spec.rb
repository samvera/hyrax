# frozen_string_literal: true

RSpec.describe Hyrax::Transactions::Steps::SyncRedirectPaths do
  subject(:step) { described_class.new }

  let(:resource_id) { 'res-1' }
  let(:permalink)   { "/concern/generic_works/#{resource_id}" }
  let(:resource_class) do
    Struct.new(:id, :redirects)
  end
  let(:resource) { resource_class.new(resource_id, redirects) }
  let(:redirects) { [{ 'path' => '/handle/1' }, { 'path' => '/handle/2' }] }

  before do
    allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
    allow(Hyrax::PermalinkPath).to receive(:call).with(resource).and_return(permalink)
    Hyrax::RedirectPath.delete_all
  end

  def existing_row(from_path:, resource_id:, **attrs)
    Hyrax::RedirectPath.create!(
      { from_path: from_path,
        to_path: "/concern/generic_works/#{resource_id}",
        permalink_path: "/concern/generic_works/#{resource_id}",
        resource_id: resource_id,
        is_display_url: false }.merge(attrs)
    )
  end

  describe '#call' do
    context 'when feature is fully enabled and resource has redirects' do
      it 'replaces existing rows for the resource with the current redirect set' do
        existing_row(from_path: '/old', resource_id: resource_id)
        result = step.call(resource)
        expect(result).to be_success
        paths = Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:from_path)
        expect(paths).to contain_exactly('/handle/1', '/handle/2')
      end

      it 'populates permalink_path with the canonical UUID URL on every row' do
        result = step.call(resource)
        expect(result).to be_success
        rows = Hyrax::RedirectPath.where(resource_id: resource_id)
        expect(rows.pluck(:permalink_path)).to all(eq(permalink))
      end
    end

    context 'with no entry marked as display URL' do
      it 'writes is_display_url=false and to_path=permalink_path on every row' do
        result = step.call(resource)
        expect(result).to be_success
        rows = Hyrax::RedirectPath.where(resource_id: resource_id)
        expect(rows.pluck(:is_display_url)).to all(be false)
        expect(rows.pluck(:to_path)).to all(eq(permalink))
      end
    end

    context 'with one entry marked as the display URL' do
      let(:redirects) do
        [{ 'path' => '/handle/1', 'is_display_url' => true },
         { 'path' => '/handle/2', 'is_display_url' => false }]
      end

      it 'writes the display row pointing at itself, non-display rows at the display path, and adds a permalink row' do
        step.call(resource)
        rows = Hyrax::RedirectPath.where(resource_id: resource_id)
        expect(rows.pluck(:from_path, :to_path, :is_display_url)).to contain_exactly(
          ['/handle/1', '/handle/1', true],
          ['/handle/2', '/handle/1', false],
          [permalink,   '/handle/1', false]
        )
      end
    end

    context 'with string is_display_url values (importer/console write)' do
      let(:redirects) do
        [{ 'path' => '/handle/1', 'is_display_url' => 'true' },
         { 'path' => '/handle/2', 'is_display_url' => 'false' }]
      end

      it 'boolean-casts the string values so only the truthy entry marks the display URL' do
        step.call(resource)
        rows = Hyrax::RedirectPath.where(resource_id: resource_id)
        expect(rows.pluck(:from_path, :is_display_url)).to contain_exactly(
          ['/handle/1', true],
          ['/handle/2', false],
          [permalink,   false]
        )
      end
    end

    context 'when the display flag moves between saves' do
      before do
        existing_row(from_path: '/handle/1', resource_id: resource_id, is_display_url: true, to_path: '/handle/1')
        existing_row(from_path: '/handle/2', resource_id: resource_id, is_display_url: false, to_path: '/handle/1')
        existing_row(from_path: permalink, resource_id: resource_id, is_display_url: false, to_path: '/handle/1')
      end

      let(:redirects) do
        [{ 'path' => '/handle/1', 'is_display_url' => false },
         { 'path' => '/handle/2', 'is_display_url' => true }]
      end

      it 'rewrites the alias rows and the permalink row to point at the new display path' do
        result = step.call(resource)
        expect(result).to be_success
        rows = Hyrax::RedirectPath.where(resource_id: resource_id)
        expect(rows.pluck(:from_path, :to_path, :is_display_url)).to contain_exactly(
          ['/handle/1', '/handle/2', false],
          ['/handle/2', '/handle/2', true],
          [permalink,   '/handle/2', false]
        )
      end
    end

    context 'when the display flag is cleared on a save' do
      before do
        existing_row(from_path: '/handle/1', resource_id: resource_id, is_display_url: true, to_path: '/handle/1')
        existing_row(from_path: '/handle/2', resource_id: resource_id, is_display_url: false, to_path: '/handle/1')
        existing_row(from_path: permalink, resource_id: resource_id, is_display_url: false, to_path: '/handle/1')
      end

      let(:redirects) do
        [{ 'path' => '/handle/1', 'is_display_url' => false },
         { 'path' => '/handle/2', 'is_display_url' => false }]
      end

      it 'removes the permalink row and writes alias rows pointing at the permalink' do
        result = step.call(resource)
        expect(result).to be_success
        rows = Hyrax::RedirectPath.where(resource_id: resource_id)
        expect(rows.pluck(:from_path, :to_path, :is_display_url)).to contain_exactly(
          ['/handle/1', permalink, false],
          ['/handle/2', permalink, false]
        )
      end
    end

    context 'when a path is already claimed by another resource' do
      before { existing_row(from_path: '/handle/1', resource_id: 'other-record') }

      it 'returns Failure with a redirect_path_collision tag' do
        result = step.call(resource)
        expect(result).to be_failure
        expect(result.failure.first).to eq(:redirect_path_collision)
      end
    end

    context 'when the underlying redirects table query raises StatementInvalid' do
      before do
        allow(Hyrax::RedirectPath).to receive(:where)
          .and_raise(ActiveRecord::StatementInvalid, 'PG::UndefinedTable: relation "hyrax_redirect_paths" does not exist')
        allow(Hyrax.logger).to receive(:error)
      end

      it 'returns Failure with a redirect_path_sync_error tag and logs the error' do
        result = step.call(resource)
        expect(result).to be_failure
        expect(result.failure.first).to eq(:redirect_path_sync_error)
        expect(Hyrax.logger).to have_received(:error).with(/sync_redirect_paths failed/)
      end
    end

    context 'when the redirects feature is inactive' do
      before { allow(Hyrax.config).to receive(:redirects_active?).and_return(false) }

      it 'is a no-op (returns Success without touching the table)' do
        expect(Hyrax::RedirectPath).not_to receive(:transaction)
        expect(step.call(resource)).to be_success
      end
    end

    context 'when the resource has no redirects attribute' do
      let(:resource_class) { Struct.new(:id) }
      let(:resource) { resource_class.new(resource_id) }

      it 'is a no-op' do
        expect(step.call(resource)).to be_success
      end
    end

    context "when the resource's redirects haven't changed since the last sync" do
      let(:original_created_at) { 1.day.ago.change(usec: 0) }

      before do
        existing_row(from_path: '/handle/1', resource_id: resource_id, created_at: original_created_at, updated_at: original_created_at)
        existing_row(from_path: '/handle/2', resource_id: resource_id, created_at: original_created_at, updated_at: original_created_at)
      end

      it 'leaves existing rows untouched (preserves created_at)' do
        result = step.call(resource)
        expect(result).to be_success

        rows = Hyrax::RedirectPath.where(resource_id: resource_id).order(:from_path)
        expect(rows.pluck(:from_path)).to eq %w[/handle/1 /handle/2]
        expect(rows.pluck(:created_at)).to all(eq(original_created_at))
      end
    end

    context "when the resource's redirects differ in order only" do
      let(:original_created_at) { 1.day.ago.change(usec: 0) }
      let(:redirects) do
        # Same paths as the existing rows, just listed in reverse order on the resource.
        [{ 'path' => '/handle/2' }, { 'path' => '/handle/1' }]
      end

      before do
        existing_row(from_path: '/handle/1', resource_id: resource_id, created_at: original_created_at, updated_at: original_created_at)
        existing_row(from_path: '/handle/2', resource_id: resource_id, created_at: original_created_at, updated_at: original_created_at)
      end

      it 'recognizes the set is unchanged and leaves rows untouched' do
        result = step.call(resource)
        expect(result).to be_success
        expect(Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:created_at))
          .to all(eq(original_created_at))
      end
    end
  end
end
