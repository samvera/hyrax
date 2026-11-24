# frozen_string_literal: true
RSpec.describe 'records/show_fields/_linked_values.html.erb', type: :view do
  let(:record) { double('presenter', value_label_pairs: [['summertime', 'Pink Pajamas']]) }
  let(:page) { Capybara.string(rendered) }
  let(:config) do
    CatalogController.blacklight_config.deep_copy.tap do |blacklight|
      blacklight.add_facet_field('creator_label_sim') unless blacklight.facet_fields.key?('creator_label_sim')
    end
  end

  before do
    allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
    allow(CatalogController).to receive(:new).and_return(instance_double(CatalogController, blacklight_config: config))
  end

  def render_field(key)
    render 'records/show_fields/linked_values', record:, key:
  end

  it 'links each value through the facet the catalog uses for it' do
    render_field(:creator)

    expect(CGI.unescape(page.find_link('Pink Pajamas')['href'])).to include('f[creator_label_sim][]=Pink Pajamas')
  end

  it "wraps each link in the field's configured microdata object" do
    render_field(:creator)

    expect(page).to have_css('span[itemprop="creator"][itemscope][itemtype="http://schema.org/Person"] span[itemprop="name"] a',
                             text: 'Pink Pajamas')
  end

  it "wraps each link in the field's configured property when it names no type" do
    render_field(:keyword)

    expect(page).to have_css('span[itemprop="keywords"]:not([itemscope]) > a', text: 'Pink Pajamas')
  end

  it "links the display values of a presenter that has no value and label pairs" do
    render 'records/show_fields/linked_values', record: double('presenter', display_values_for: ['Pink Pajamas']), key: :creator

    expect(page).to have_link('Pink Pajamas')
  end

  it 'renders a bare link for a field with no configured property' do
    render_field(:resource_type)

    expect(page).to have_no_css('[itemprop]')
    expect(page).to have_link('Pink Pajamas')
  end
end
