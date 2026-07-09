# frozen_string_literal: true

RSpec.describe 'hyrax/file_sets/_metadata.html.erb', type: :view do
  let(:doc) do
    {
      'has_model_ssim' => ['FileSet'],
      :id => '123',
      'creator_tesim' => ['Jane Smith'],
      'keyword_tesim' => ['cats', 'dogs'],
      'license_tesim' => ['https://creativecommons.org/licenses/by/4.0/']
    }
  end
  let(:solr_doc) { SolrDocument.new(doc) }
  let(:ability) { double }
  let(:presenter) { Hyrax::FileSetPresenter.new(solr_doc, ability) }

  before do
    assign(:presenter, presenter)
  end

  context 'when not using flexible metadata' do
    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(false)
      render
    end

    it 'renders creator' do
      expect(rendered).to have_selector('dd', text: 'Jane Smith')
    end

    it 'renders multiple keyword values joined' do
      expect(rendered).to have_selector('dd', text: 'cats, dogs')
    end

    it 'renders license as a link' do
      expect(rendered).to have_selector('dd a[href="https://creativecommons.org/licenses/by/4.0/"]')
    end
  end

  context 'with an inline compound and flexible metadata disabled' do
    let(:compound_schema) { instance_double(Hyrax::CompoundSchema, inline_compound_names: [:provenance], card?: false) }

    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(false)
      allow(view).to receive(:compound_schema_for).and_return(compound_schema)
      allow(presenter).to receive(:provenance).and_return([{ 'scheme' => 'C2PA' }])
      allow(presenter).to receive(:attribute_to_html)
        .with(:provenance, render_as: :compound, html_dl: true)
        .and_return('<dt>Provenance</dt><dd>Scheme: C2PA</dd>'.html_safe)
      render
    end

    it 'renders the inline compound even with flexibility off' do
      expect(presenter).to have_received(:attribute_to_html).with(:provenance, render_as: :compound, html_dl: true)
      expect(rendered).to have_selector('dd', text: 'Scheme: C2PA')
    end
  end

  context 'with an inline compound and flexible metadata enabled' do
    let(:compound_schema) { instance_double(Hyrax::CompoundSchema, inline_compound_names: [:provenance], card?: false) }

    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      # FileSet#flexible? is driven by the document's schema_version, not the
      # global config, so stub it directly to exercise the flexible branch.
      allow(presenter).to receive(:flexible?).and_return(true)
      allow(view).to receive(:compound_schema_for).and_return(compound_schema)
      # A flexible profile declares the compound's display label. conform_options
      # resolves it (the same path the scalar rows use) - the multi-word label is
      # passed through humanize, hence 'Provenance statement', and it differs from
      # the humanized field name ('Provenance'), so the assertion proves the
      # declared label - not the renderer's field-name fallback - is what reaches
      # attribute_to_html.
      # render_as: compound is what the metadata partial keys off to route a field
      # to the compound renderer (mirroring works/collections), so the stub carries it.
      allow(view).to receive(:view_options_for).and_return(
        { provenance: { display_label: { default: 'Provenance Statement' }, render_as: 'compound' } }
      )
      allow(presenter).to receive(:provenance).and_return([{ 'scheme' => 'C2PA' }])
      # The partial routes the compound through the standard attribute_to_html
      # path - passing the field's resolved view_options (which carry render_as)
      # rather than a hand-built render_as: argument - exactly as works/collections
      # do. hash_including ignores incidental keys conform_options adds (base_url).
      allow(presenter).to receive(:attribute_to_html)
        .with(:provenance, hash_including(render_as: 'compound', html_dl: true, label: 'Provenance statement'))
        .and_return('<dt>Provenance statement</dt><dd>Scheme: C2PA</dd>'.html_safe)
      render
    end

    it 'renders the inline compound via the standard path with its declared label' do
      expect(presenter).to have_received(:attribute_to_html)
        .with(:provenance, hash_including(render_as: 'compound', html_dl: true, label: 'Provenance statement'))
      expect(rendered).to have_selector('dt', text: 'Provenance statement')
    end
  end

  context 'with a non-visible inline compound (admin_only) and a non-admin user' do
    let(:compound_schema) { instance_double(Hyrax::CompoundSchema, inline_compound_names: [:provenance], card?: false) }

    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      allow(presenter).to receive(:flexible?).and_return(true)
      allow(view).to receive(:compound_schema_for).and_return(compound_schema)
      allow(view).to receive(:current_user).and_return(double(admin?: false))
      # The compound declares admin_only, so field_visible? should gate it out for
      # a non-admin - the same gate scalars get. Regression test: before the
      # single-pass refactor, inline compounds were rendered from a separate loop
      # that never consulted field_visible?, leaking admin_only/show_page fields.
      allow(view).to receive(:view_options_for).and_return(
        { provenance: { display_label: { default: 'Provenance Statement' }, render_as: 'compound', admin_only: true } }
      )
      allow(presenter).to receive(:provenance).and_return([{ 'scheme' => 'C2PA' }])
      allow(presenter).to receive(:attribute_to_html)
      render
    end

    it 'does not render the compound and never calls the renderer' do
      expect(presenter).not_to have_received(:attribute_to_html)
      expect(rendered).not_to have_selector('dd', text: 'C2PA')
    end
  end

  context 'when using flexible metadata' do
    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      # Exercise the flexible branch (driven by the document's schema_version).
      allow(presenter).to receive(:flexible?).and_return(true)
      allow(view).to receive(:view_options_for).and_return(
        {
          creator: { 'display_label' => { 'en' => 'Creator', 'default' => 'Creator' } },
          keyword: { 'display_label' => { 'en' => 'Keyword', 'default' => 'Keyword' } },
          license: { 'display_label' => { 'en' => 'License', 'default' => 'License' } }
        }
      )
      render
    end

    it 'renders each visible field through the standard attribute_to_html path' do
      expect(rendered).to have_selector('dd', text: 'Jane Smith')
      expect(rendered).to have_selector('dd', text: /cats/)
      expect(rendered).to have_selector('dd', text: /dogs/)
      expect(rendered).to have_selector('dd a[href="https://creativecommons.org/licenses/by/4.0/"]')
    end

    it 'splits the visible rows across two col-md-6 columns (left gets ceil(n/2))' do
      node = Capybara.string(rendered)
      columns = node.all('.col-md-6')
      expect(columns.size).to eq(2)
      expect(columns[0]).to have_selector('dt', count: 2)
      expect(columns[1]).to have_selector('dt', count: 1)
    end
  end
end
