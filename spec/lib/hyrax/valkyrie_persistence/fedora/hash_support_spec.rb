# frozen_string_literal: true

RSpec.describe 'Storing plain Hash values through the Valkyrie Fedora adapter', :clean_repo do
  before do
    skip 'requires the Valkyrie Fedora metadata adapter' unless Hyrax.metadata_adapter.is_a?(Valkyrie::Persistence::Fedora::MetadataAdapter)
    class FedoraHashResource < Hyrax::Resource
      attribute :aliases, Valkyrie::Types::Array.of(Valkyrie::Types::Hash)
    end
  end
  after { Object.send(:remove_const, :FedoraHashResource) if defined?(FedoraHashResource) }

  def reload(entries)
    saved = Hyrax.persister.save(resource: FedoraHashResource.new(aliases: entries))
    Hyrax.query_service.find_by(id: saved.id).aliases
  end

  it 'reloads an array of hashes exactly, with no nested-resource keys' do
    entries = [{ path: '/one', is_display_url: true }, { path: '/two', is_display_url: false }]
    expect(reload(entries)).to contain_exactly(*entries)
  end

  it 'reloads one-key hashes as separate entries' do
    entries = [{ name: 'Ada' }, { role: 'Editor' }]
    expect(reload(entries)).to contain_exactly(*entries)
  end

  it "leaves the caller's hashes unchanged when saving" do
    entries = [{ path: '/one' }]
    reload(entries)
    expect(entries).to eq [{ path: '/one' }]
  end
end
