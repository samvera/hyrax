RSpec.describe 'hyrax/my/collections/_list_collections.html.erb', type: :view do
  let(:id) { "3197z511f" }
  let(:modified_date) {  DateTime.new(2014, 1, 1).iso8601 }

  context "check for collections" do
    let(:attributes) do
      {
        id: id,
        "has_model_ssim" => ["Collection"],
        "title_tesim" => ["Collection Title"],
        "description_tesim" => ["Collection Description"],
        "collection_type_gid_ssim" => [collection_type.gid],
        "system_modified_dtsi" => modified_date
      }
    end

    let(:doc) { SolrDocument.new(attributes) }
    let(:collection) { mock_model(Collection) }
    let(:collection_type) { create(:collection_type) }
    let(:collection_presenter) { Hyrax::CollectionPresenter.new(doc, Ability.new(build(:user)), nil) }

    before do
      allow(view).to receive(:current_user).and_return(stub_model(User))
      allow(view).to receive(:can?).with(:edit, doc).and_return(true)
      allow(view).to receive(:can?).with(:deposit, doc).and_return(true)
      allow(doc).to receive(:to_model).and_return(stub_model(Collection, id: id))
      allow(Collection).to receive(:find).with(id).and_return(collection)
      allow(collection).to receive(:id).and_return(id)
      allow(collection).to receive(:member_of_collection_ids).and_return(["abc", "123"])
      allow(collection_presenter).to receive(:collection_type_badge).and_return("User Collection")
      view.lookup_context.prefixes.push 'hyrax/my'

      render 'hyrax/my/collections/list_collections', collection_presenter: collection_presenter
    end

    it 'the line item displays the work and its actions' do
      expect(rendered).to have_selector("tr#document_#{id}")
      expect(rendered).to have_link 'Collection Title', href: hyrax.dashboard_collection_path(id)
      expect(rendered).to have_link 'Edit collection', href: hyrax.edit_dashboard_collection_path(id)
      expect(rendered).to have_link 'Delete collection', href: hyrax.dashboard_collection_path(id)
      expect(rendered).to have_css 'a.visibility-link', text: 'Private'
      expect(rendered).to have_css '.collection_type', text: 'User Collection'
      expect(rendered).to have_selector '.expanded-details', text: 'Collection Description'
      expect(rendered).not_to include '<span class="fa fa-cubes collection-icon-small"></span></a>'
      expect(rendered).to include Date.parse(modified_date).to_formatted_s(:standard)
    end
  end

  context "check for admin set" do
    let(:attributes) do
      {
        id: id,
        "has_model_ssim" => ["AdminSet"],
        "title_tesim" => ["AdminSet Title"],
        "description_tesim" => ["Admin Description"],
        "collection_type_gid_ssim" => [collection_type.gid],
        "system_modified_dtsi" => modified_date
      }
    end

    let(:doc) { SolrDocument.new(attributes) }
    let(:admin_set) { mock_model(AdminSet) }
    let(:collection_type) { create(:admin_set_collection_type) }
    let(:collection_presenter) { Hyrax::AdminSetPresenter.new(doc, Ability.new(build(:user)), nil) }

    before do
      allow(view).to receive(:current_user).and_return(stub_model(User))
      allow(view).to receive(:can?).with(:edit, doc).and_return(true)
      allow(doc).to receive(:to_model).and_return(stub_model(AdminSet, id: id))
      allow(collection_presenter).to receive(:collection_type_badge).and_return("Admin Set")
      view.lookup_context.prefixes.push 'hyrax/my'

      render 'hyrax/my/collections/list_collections', collection_presenter: collection_presenter
    end

    it 'the line item displays the work and its actions' do
      expect(rendered).to include 'title="Delete collection" data-totalitems="0" data-membership="true" data-hasaccess="true"'
      expect(rendered).to have_selector("tr#document_#{id}")
      expect(rendered).to have_link 'AdminSet Title', href: '#'
      expect(rendered).to have_link 'View collection', href: hyrax.admin_admin_set_path(id)
      expect(rendered).to have_link 'Edit collection', href: hyrax.edit_admin_admin_set_path(id)
      expect(rendered).to have_link 'Delete collection', href: hyrax.admin_admin_set_path(id)
      expect(rendered).to have_link 'Add to collection' if Hyrax::CollectionType.any_nestable?
      expect(rendered).to have_css '.collection_type', text: 'Admin Set'
      expect(rendered).to have_selector '.expanded-details', text: 'Admin Description'
      expect(rendered).not_to include '<span class="fa fa-cubes collection-icon-small"></span></a>'
      expect(rendered).to include Date.parse(modified_date).to_formatted_s(:standard)
    end
  end
end
