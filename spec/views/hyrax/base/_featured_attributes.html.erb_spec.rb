# frozen_string_literal: true

# Covers the default rendering of `view: { position: featured }`: a property so
# flagged renders prominently above the metadata table as a labeled, sanitized
# HTML card. Multiple featured properties each render their own card; non-featured
# or blank fields render nothing.
RSpec.describe 'hyrax/base/featured_attributes', type: :view do
  let(:ability) { double }
  let(:solr_document) { SolrDocument.new(has_model_ssim: 'GenericWork') }
  let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, ability) }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    # conform_field maps a (possibly flexible) field to the presenter method name;
    # for these specs the field name is the method name. conform_options resolves
    # the human label the same way the metadata table does.
    allow(view).to receive(:conform_field) { |field, _opts| field }
    allow(view).to receive(:conform_options) { |field, _opts| { label: field.to_s.titleize } }
  end

  context 'with a field flagged view: { position: featured }' do
    before do
      allow(view).to receive(:view_options_for).with(presenter)
                                               .and_return('description' => { 'position' => 'featured', 'render_as' => 'html' })
      allow(presenter).to receive(:description)
        .and_return(['<p>Featured <strong>narrative</strong></p><script>alert(1)</script>'])
    end

    it 'renders the value as a labeled card, stripping disallowed tags' do
      render 'hyrax/base/featured_attributes', presenter: presenter

      expect(page).to have_css('section.work-featured-attribute.attribute-description h2', text: 'Description')
      expect(page).to have_css('section.work-featured-attribute.attribute-description strong', text: 'narrative')
      expect(rendered).to include('<strong>narrative</strong>')
      expect(rendered).not_to include('<script>')
    end
  end

  context 'with more than one field flagged featured' do
    before do
      allow(view).to receive(:view_options_for).with(presenter)
                                               .and_return('description' => { 'position' => 'featured' },
                                                           'abstract' => { 'position' => 'featured' })
      allow(presenter).to receive(:description).and_return(['First featured block'])
      allow(presenter).to receive(:abstract).and_return(['Second featured block'])
    end

    it 'renders each featured property as its own labeled card' do
      render 'hyrax/base/featured_attributes', presenter: presenter

      expect(page).to have_css('section.work-featured-attribute', count: 2)
      expect(page).to have_css('section.attribute-description h2', text: 'Description')
      expect(page).to have_css('section.attribute-description', text: 'First featured block')
      expect(page).to have_css('section.attribute-abstract h2', text: 'Abstract')
      expect(page).to have_css('section.attribute-abstract', text: 'Second featured block')
    end
  end

  context 'when no field is flagged featured' do
    before do
      allow(view).to receive(:view_options_for).with(presenter)
                                               .and_return('title' => { 'position' => 'inline' })
      allow(presenter).to receive(:title).and_return(['A title'])
    end

    it 'renders nothing' do
      render 'hyrax/base/featured_attributes', presenter: presenter

      expect(rendered.strip).to be_blank
    end
  end

  context 'when the featured field is blank' do
    before do
      allow(view).to receive(:view_options_for).with(presenter)
                                               .and_return('description' => { 'position' => 'featured' })
      allow(presenter).to receive(:description).and_return([])
    end

    it 'does not render an empty featured section' do
      render 'hyrax/base/featured_attributes', presenter: presenter

      expect(page).not_to have_css('section.work-featured-attribute')
    end
  end
end
