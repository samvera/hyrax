# frozen_string_literal: true
RSpec.describe 'hyrax/collections/show.html.erb', type: :view do
  let(:document) do
    SolrDocument.new(id: 'xyz123z4',
                     'collection_type_gid_ssim' => [collection_type.gid],
                     'title_tesim' => ['Make Collections Great Again'],
                     'rights_tesim' => ["http://creativecommons.org/licenses/by-sa/3.0/us/"])
  end
  let(:ability) { double }
  let(:collection_type) { create(:collection_type) }
  let(:presenter) { Hyrax::CollectionPresenter.new(document, ability) }

  before do
    allow(document).to receive(:hydra_model).and_return(::Collection)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(view).to receive(:can?).with(:edit, document).and_return(false)
    allow(view).to receive(:can?).with(:destroy, document).and_return(false)
    allow(presenter).to receive(:collection_type_is_nestable?).and_return(true)
    allow(presenter).to receive(:total_items).and_return(0)
    allow(presenter).to receive(:total_viewable_items).and_return(0)
    allow(presenter).to receive(:banner_file).and_return("banner.gif")
    allow(presenter).to receive(:logo_record).and_return([{ linkurl: "logo link url", alttext: "logo alt text", file_location: "logo.gif" }])
    assign(:subcollection_count, 0)
    assign(:parent_collection_count, 0)
    assign(:members_count, 0)
    allow(ability).to receive(:user_groups).and_return([])
    allow(ability).to receive(:current_user).and_return(build(:user, id: nil, email: ""))
    assign(:presenter, presenter)

    # Stub route because view specs don't handle engine routes
    allow(view).to receive(:collection_path).and_return("/collection/123")

    stub_template '_search_form.html.erb' => 'search form'
    stub_template 'hyrax/collections/_sort_and_per_page.html.erb' => 'sort and per page'
    stub_template 'hyrax/collections/_document_list.html.erb' => 'document list'
    stub_template 'hyrax/collections/_paginate.html.erb' => 'paginate'
    stub_template 'hyrax/collections/_media_display.html.erb' => '<span class="fa fa-cubes collection-icon-search"></span>'
    render
  end

  it 'draws the page' do
    expect(rendered).to have_content('Make Collections Great Again')
    expect(rendered).to have_content('Collection Details')
    expect(rendered).to have_css('div.hyc-banner')
    expect(rendered).to have_css('div.hyc-description')
    expect(rendered).to have_css('div.hyc-metadata')
    expect(rendered).to have_css('div.hyc-logos')
  end
end
