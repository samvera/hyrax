# frozen_string_literal: true
RSpec.describe 'hyrax/my/_collection_action_menu.html.erb' do
  let(:id) { '123' }
  let(:collection_doc) { SolrDocument.new(id: id, has_model_ssim: 'Collection') }
  let(:user) { build(:user) }
  let(:ability) { instance_double("Ability") }
  let(:collection_presenter) { Hyrax::CollectionPresenter.new(collection_doc, ability, nil) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:collection_presenter).and_return(collection_presenter)
    allow(collection_presenter).to receive(:id).and_return(id)
    allow(collection_presenter).to receive(:total_items).and_return(0)
    allow(collection_presenter).to receive(:collection_type_is_require_membership?).and_return(false)
    allow(collection_presenter).to receive(:collection_type_is_nestable?).and_return(false)
    allow(Flipflop).to receive(:read_only?).and_return(false)

    allow(view).to receive(:can?).with(:read, collection_doc).and_return(true)
    allow(view).to receive(:can?).with(:edit, collection_doc).and_return(true)
  end

  context "when user can edit" do
    before do
      allow(view).to receive(:can?).with(:edit, collection_doc).and_return(true)
      render 'hyrax/my/collection_action_menu', collection: collection_doc
    end

    it "shows view, edit, and delete" do
      expect(rendered).to have_link 'View collection', href: hyrax.dashboard_collection_path(id)
      expect(rendered).to have_link 'Edit collection', href: hyrax.edit_dashboard_collection_path(id)
      expect(rendered).to have_link 'Delete collection'
    end
  end

  context "when user can not edit" do
    before do
      allow(view).to receive(:can?).with(:edit, collection_doc).and_return(false)
      render 'hyrax/my/collection_action_menu', collection: collection_doc
    end

    it "shows view, delete and hide edit" do
      expect(rendered).to have_link 'View collection', href: hyrax.dashboard_collection_path(id)
      expect(rendered).not_to have_link 'Edit collection', href: hyrax.edit_dashboard_collection_path(id)
      expect(rendered).to have_link 'Delete collection'
    end
  end

  context "when nestable" do
    before do
      allow(collection_presenter)
        .to receive(:collection_type_is_nestable?)
        .and_return(true)
    end

    it "shows add to collection action " do
      render 'hyrax/my/collection_action_menu', collection: collection_doc
      expect(rendered).to have_link 'Add to collection'
    end
  end

  context "when not nestable" do
    it "hides add to collection action " do
      render 'hyrax/my/collection_action_menu', collection: collection_doc
      expect(rendered).not_to have_link 'Add to collection'
    end
  end
end
