# frozen_string_literal: true
RSpec.describe 'hyrax/my/collections/_list_collections.html.erb', type: :view do
  let(:id) { "3197z511f" }
  let(:modified_date) {  DateTime.new(2014, 1, 1).iso8601 }

  def check_tr_data_attributes
    expect(rendered).to have_selector('tr[data-source="my"]')
    expect(rendered).to have_selector("tr[data-id='#{id}']")
    expect(rendered).to have_selector("tr[data-colls-hash]")
    expect(rendered).to have_selector("tr[data-post-url='/dashboard/collections/#{id}/within']")
  end

  context "check for collections" do
    let(:attributes) do
      {
        id: id,
        "has_model_ssim" => ["Collection"],
        "title_tesim" => ["Collection Title"],
        "description_tesim" => ["Collection Description"],
        "thumbnail_path_ss" => Hyrax::CollectionIndexer.thumbnail_path_service.default_image,
        "collection_type_gid_ssim" => [collection_type.to_global_id.to_s],
        "system_modified_dtsi" => modified_date
      }
    end

    let(:doc) { SolrDocument.new(attributes) }
    let(:collection_type) { FactoryBot.build(:collection_type, id: 'coltype_id') }
    let(:collection_presenter) { Hyrax::CollectionPresenter.new(doc, Ability.new(build(:user)), nil) }

    before do
      allow(view).to receive(:can?).with(:edit, doc).and_return(true)
      allow(view).to receive(:can?).with(:read, doc).and_return(true)
      allow(Hyrax::CollectionType).to receive(:any_nestable?).and_return(true)
      allow(collection_presenter).to receive(:collection_type_badge).and_return("User Collection")
      allow(collection_presenter).to receive(:allow_batch?).and_return(true)
      allow(collection_presenter).to receive(:total_viewable_items).and_return(0)
      allow(collection_presenter).to receive(:total_items).and_return(0)
      allow(collection_presenter).to receive(:collection_type_is_require_membership?).and_return(true)
      allow(collection_presenter).to receive(:collection_type_is_nestable?).and_return(true)

      allow(view)
        .to receive(:available_parent_collections_data)
        .with(collection: collection_presenter)
        .and_return([mock_model('MockCollection')])

      view.lookup_context.prefixes.push 'hyrax/my'
      render 'hyrax/my/collections/list_collections', collection_presenter: collection_presenter, is_admin_set: doc.admin_set?
    end

    it 'the line item displays the collection and its actions' do
      expect(rendered).to have_selector("tr#document_#{id}")
      check_tr_data_attributes
      expect(rendered).to have_selector("tr[data-post-delete-url='/dashboard/collections/#{id}']")
      expect(rendered).to have_link 'Collection Title', href: hyrax.dashboard_collection_path(id, locale: I18n.locale)
      expect(rendered).to have_link 'Edit collection', href: hyrax.edit_dashboard_collection_path(id)
      expect(rendered).to have_link 'Delete collection'
      expect(rendered).to have_link 'Add to collection'
      expect(rendered).to have_css '.collection_type', text: 'User Collection'
      expect(rendered).to have_selector '.expanded-details', text: 'Collection Description'
      expect(rendered).not_to have_selector 'span.fa-cubes'
      expect(rendered).to have_selector '.thumbnail-wrapper > img'
      expect(rendered).to include Date.parse(modified_date).to_formatted_s('%Y-%m-%d')
    end
  end

  context "check for admin set" do
    let(:attributes) do
      {
        id: id,
        "has_model_ssim" => ["AdminSet"],
        "title_tesim" => ["AdminSet Title"],
        "description_tesim" => ["Admin Description"],
        "thumbnail_path_ss" => Hyrax::AdminSetIndexer.thumbnail_path_service.default_image,
        "collection_type_gid_ssim" => [collection_type.to_global_id.to_s],
        "system_modified_dtsi" => modified_date
      }
    end

    let(:doc) { SolrDocument.new(attributes) }
    let(:admin_set) { mock_model(AdminSet) }
    let(:collection_type) { build(:admin_set_collection_type) }
    let(:collection_presenter) { Hyrax::AdminSetPresenter.new(doc, Ability.new(build(:user)), nil) }

    before do
      allow(view).to receive(:current_user).and_return(stub_model(User))
      allow(view).to receive(:can?).with(:edit, doc).and_return(true)
      allow(doc).to receive(:to_model).and_return(stub_model(AdminSet, id: id))
      allow(collection_presenter).to receive(:collection_type_badge).and_return("Admin Set")
      allow(collection_presenter).to receive(:allow_batch?).and_return(true)
      allow(collection_presenter).to receive(:total_viewable_items).and_return(0)
      allow(collection_presenter).to receive(:total_items).and_return(0)
      view.lookup_context.prefixes.push 'hyrax/my'

      render 'hyrax/my/collections/list_collections', collection_presenter: collection_presenter, is_admin_set: doc.admin_set?
    end

    it 'the line item displays the work and its actions' do
      expect(rendered).to include 'title="Delete collection" data-totalitems="0" data-membership="true" data-hasaccess="true"'
      expect(rendered).to have_selector("tr#document_#{id}")
      check_tr_data_attributes
      expect(rendered).to have_selector("tr[data-post-delete-url='/admin/admin_sets/#{id}']")
      expect(rendered).to have_link 'AdminSet Title', href: '#'
      expect(rendered).to have_link 'View collection', href: hyrax.admin_admin_set_path(id)
      expect(rendered).to have_link 'Edit collection', href: hyrax.edit_admin_admin_set_path(id)
      expect(rendered).to have_link 'Delete collection'
      expect(rendered).to have_link 'Add to collection' if Hyrax::CollectionType.any_nestable?
      expect(rendered).to have_css '.collection_type', text: 'Admin Set'
      expect(rendered).to have_selector '.expanded-details', text: 'Admin Description'
      expect(rendered).not_to have_selector 'span.fa-cubes'
      expect(rendered).to have_selector '.thumbnail-wrapper > img'
      expect(rendered).to include Date.parse(modified_date).to_formatted_s('%Y-%m-%d')
    end
  end
end
