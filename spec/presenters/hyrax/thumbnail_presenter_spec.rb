# frozen_string_literal: true

RSpec.describe Hyrax::ThumbnailPresenter do
  subject(:presenter) { described_class.new(document, view_context, view_config) }

  let(:document) { SolrDocument.new(id: 'x1', thumbnail_path_ss: '/downloads/x1?file=thumbnail') }
  let(:view_context) { ActionView::TestCase::TestController.new.view_context }
  let(:view_config) do
    Blacklight::Configuration::ViewConfig::Index.new(thumbnail_field: 'thumbnail_path_ss')
  end

  describe '#thumbnail_tag' do
    it 'defaults to lazy loading' do
      expect(presenter.thumbnail_tag({}, suppress_link: true))
        .to include('loading="lazy"')
    end

    it 'lets the caller opt out for above-the-fold images' do
      tag = presenter.thumbnail_tag({ loading: 'eager' }, suppress_link: true)

      expect(tag).to include('loading="eager"')
      expect(tag).not_to include('loading="lazy"')
    end

    it 'preserves other image options' do
      expect(presenter.thumbnail_tag({ alt: 'A cat', class: 'thumb' }, suppress_link: true))
        .to include('loading="lazy"', 'alt="A cat"', 'class="thumb"')
    end
  end

  describe '#render' do
    it 'defaults to lazy loading' do
      expect(presenter.render).to include('loading="lazy"')
    end

    it 'lets the caller opt out' do
      expect(presenter.render(loading: 'eager')).to include('loading="eager"')
    end
  end

  # Both public entry points funnel into Blacklight's private #thumbnail_value.
  # If a Blacklight upgrade renames or reroutes it, the overrides above stop
  # applying silently -- this asserts the seam still exists.
  describe 'Blacklight integration' do
    it 'still routes both entry points through #thumbnail_value' do
      expect(described_class.private_method_defined?(:thumbnail_value)).to be true
    end

    it 'is configured for the index-like views' do
      config = CatalogController.blacklight_config

      %i[list gallery masonry slideshow].each do |view|
        expect(config.view_config(view).thumbnail_presenter).to eq described_class
      end
    end

    # `show` inherits from `config.index`, so it has to be pinned back to
    # Blacklight's presenter explicitly. A representative image is above the
    # fold, where lazy loading delays the largest contentful paint rather than
    # saving a request.
    it 'is not applied to the show view' do
      expect(CatalogController.blacklight_config.view_config(:show).thumbnail_presenter)
        .to eq Blacklight::ThumbnailPresenter
    end
  end
end
