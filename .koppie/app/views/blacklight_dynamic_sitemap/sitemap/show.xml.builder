# frozen_string_literal: true

xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.urlset(
  'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
  'xsi:schemaLocation' => 'http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd',
  'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9'
) do
  config = BlacklightDynamicSitemap::Engine.config
  @sitemap_entries.each do |doc|
    solr_doc = SolrDocument.new(doc)

    xml.url do
      # Use Hyrax's routing logic: collections go through hyrax engine, works through main_app
      url_parts = solr_doc.collection? ? [hyrax, solr_doc] : [main_app, solr_doc]
      xml.loc(polymorphic_url(url_parts))

      last_modified = doc[config.last_modified_field]
      xml.lastmod(config.format_last_modified&.call(last_modified) || last_modified)
    end
  end
end
