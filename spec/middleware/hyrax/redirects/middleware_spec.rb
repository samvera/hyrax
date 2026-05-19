# frozen_string_literal: true

require 'hyrax/redirects/middleware'

RSpec.describe Hyrax::Redirects::Middleware do
  let(:downstream_app) { ->(env) { [200, { 'Content-Type' => 'text/plain' }, [env['PATH_INFO']]] } }
  let(:middleware)     { described_class.new(downstream_app) }
  let(:resource_id)    { 'res-1' }

  def env_for(path, method: 'GET')
    { 'PATH_INFO' => path, 'REQUEST_METHOD' => method }
  end

  before do
    Hyrax::RedirectPath.delete_all
    Rails.cache.clear
    allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
    allow(Hyrax.config).to receive(:reserved_redirect_prefixes).and_return(['/dashboard'])
  end

  context 'when redirects_active? is false' do
    before { allow(Hyrax.config).to receive(:redirects_active?).and_return(false) }

    it 'passes the request straight through to the downstream app' do
      expect(Hyrax::Redirects::Resolver).not_to receive(:call)
      status, = middleware.call(env_for('/some/path'))
      expect(status).to eq(200)
    end
  end

  context 'for non-GET requests' do
    it 'passes through without consulting the resolver' do
      expect(Hyrax::Redirects::Resolver).not_to receive(:call)
      middleware.call(env_for('/handle/12345/678', method: 'POST'))
    end
  end

  context 'for paths that should be skipped' do
    it 'skips reserved-prefix paths' do
      expect(Hyrax::Redirects::Resolver).not_to receive(:call)
      middleware.call(env_for('/dashboard/whatever'))
    end

    it 'skips the bare root path' do
      expect(Hyrax::Redirects::Resolver).not_to receive(:call)
      middleware.call(env_for('/'))
    end

    it 'does not skip dotted paths (handle.net-style aliases are legitimate)' do
      expect(Hyrax::Redirects::Resolver).to receive(:call).with('/handle/2027.42/12345').and_return(nil)
      middleware.call(env_for('/handle/2027.42/12345'))
    end
  end

  context 'with a non-display alias and a sibling display row' do
    before do
      Hyrax::RedirectPath.create!(path: '/handle/12345/678', resource_id: resource_id, display_url: false)
      Hyrax::RedirectPath.create!(path: '/robs-cat-study', resource_id: resource_id, display_url: true)
    end

    it 'returns a 301 to the sibling display path' do
      status, headers, body = middleware.call(env_for('/handle/12345/678'))
      expect(status).to eq(301)
      expect(headers['Location']).to eq('/robs-cat-study')
      expect(body).to eq([])
    end

    it 'emits a relative Location header (no scheme/host) so multi-domain tenants stay on the visitor host' do
      _, headers, = middleware.call(env_for('/handle/12345/678'))
      expect(headers['Location']).to start_with('/')
      expect(headers['Location']).not_to include('://')
    end

    it 'sets Cache-Control: no-cache so browsers re-check on every visit' do
      _, headers, = middleware.call(env_for('/handle/12345/678'))
      expect(headers['Cache-Control']).to eq('no-cache')
    end

    it 'sets Turbolinks-Location so Turbolinks updates the address bar' do
      _, headers, = middleware.call(env_for('/handle/12345/678'))
      expect(headers['Turbolinks-Location']).to eq('/robs-cat-study')
    end
  end

  context 'with the display alias itself' do
    let(:render_path) { "/concern/generic_works/#{resource_id}" }

    before do
      Hyrax::RedirectPath.create!(path: '/robs-cat-study', resource_id: resource_id, display_url: true)
      allow(Hyrax::Redirects::Resolver).to receive(:call).with('/robs-cat-study').and_return(render_path: render_path)
    end

    it 'rewrites PATH_INFO and lets the downstream app handle the rewritten path' do
      env = env_for('/robs-cat-study')
      status, _, body = middleware.call(env)
      expect(status).to eq(200)
      expect(env['PATH_INFO']).to eq(render_path)
      expect(body.first).to eq(render_path)
    end

    it 'marks the env so downstream controllers can detect the rewrite' do
      env = env_for('/robs-cat-study')
      middleware.call(env)
      expect(env['hyrax.redirects.rewrote']).to be(true)
    end

    it 'sets Turbolinks-Location to the visited alias path' do
      env = env_for('/robs-cat-study')
      _, headers, = middleware.call(env)
      expect(headers['Turbolinks-Location']).to eq('/robs-cat-study')
    end
  end

  context 'with no matching row' do
    it 'passes through to the downstream app (Rails handles the 404)' do
      status, _, body = middleware.call(env_for('/no-such-path'))
      expect(status).to eq(200) # the test downstream app returns 200; in real app Rails would 404
      expect(body.first).to eq('/no-such-path')
    end
  end

  context 'caching' do
    before do
      Hyrax::RedirectPath.create!(path: '/handle/12345/678', resource_id: resource_id, display_url: false)
      Hyrax::RedirectPath.create!(path: '/robs-cat-study', resource_id: resource_id, display_url: true)
    end

    it 'consults the resolver at most once per path within the TTL' do
      allow(Hyrax::Redirects::Resolver).to receive(:call).and_call_original
      2.times { middleware.call(env_for('/handle/12345/678')) }
      expect(Hyrax::Redirects::Resolver).to have_received(:call).once
    end
  end
end
