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

      it 'populates to_path and permalink_path with the canonical UUID URL on every row' do
        result = step.call(resource)
        expect(result).to be_success
        rows = Hyrax::RedirectPath.where(resource_id: resource_id)
        expect(rows.pluck(:to_path)).to all(eq(permalink))
        expect(rows.pluck(:permalink_path)).to all(eq(permalink))
        expect(rows.pluck(:is_display_url)).to all(be(false))
      end

      it 'busts the cache for both old and new paths' do
        existing_row(from_path: '/old', resource_id: resource_id)
        expect(Hyrax::RedirectCacheBuster).to receive(:call)
          .with(array_including('/old', '/handle/1', '/handle/2'))
        step.call(resource)
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

      it 'does not bust the cache' do
        expect(Hyrax::RedirectCacheBuster).not_to receive(:call)
        step.call(resource)
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
