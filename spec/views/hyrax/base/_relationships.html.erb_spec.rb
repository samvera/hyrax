# frozen_string_literal: true
RSpec.describe 'hyrax/base/relationships', type: :view do
  let(:user) { create(:user, groups: 'admin') }
  let(:ability) { Ability.new(user) }
  let(:solr_doc) { instance_double(SolrDocument, id: '123', human_readable_type: 'Work', admin_set: nil) }
  let(:presenter) { Hyrax::WorkShowPresenter.new(solr_doc, ability) }
  let(:generic_work) do
    Hyrax::WorkShowPresenter.new(
      SolrDocument.new(
        id: '456',
        has_model_ssim: ['GenericWork'],
        title_tesim: ['Containing work']
      ),
      ability
    )
  end

  let(:collection) do
    Hyrax::CollectionPresenter.new(
      SolrDocument.new(
        id: '345',
        has_model_ssim: ['Collection'],
        title_tesim: ['Containing collection']
      ),
      ability
    )
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }

  context "when collections are present and no parents are present" do
    let(:member_of_collection_presenters) { [collection] }

    before do
      allow(controller).to receive(:current_user).and_return user
      allow(view).to receive(:contextual_path).and_return("/collections/456")
      allow(presenter).to receive(:member_of_collection_presenters).and_return(member_of_collection_presenters)
      render 'hyrax/base/relationships', presenter: presenter
    end
    it "links to collections" do
      expect(page).to have_text 'In Collection'
      expect(page).to have_link 'Containing collection'
      expect(page).not_to have_text 'In Generic work'
    end
  end

  context "when parents are present and no collections are present" do
    let(:member_of_collection_presenters) { [generic_work] }

    before do
      allow(controller).to receive(:current_user).and_return user
      allow(view).to receive(:contextual_path).and_return("/concern/generic_works/456")
      allow(presenter).to receive(:member_of_collection_presenters).and_return(member_of_collection_presenters)
      render 'hyrax/base/relationships', presenter: presenter
    end
    it "links to work" do
      expect(page).to have_text 'In Generic work'
      expect(page).to have_link 'Containing work'
      expect(page).not_to have_text 'In Collection'
    end
  end

  context "when parents are present and collections are present" do
    let(:member_of_collection_presenters) { [generic_work, collection] }

    before do
      allow(controller).to receive(:current_user).and_return user
      allow(view).to receive(:contextual_path).and_return("/concern/generic_works/456")
      allow(presenter).to receive(:member_of_collection_presenters).and_return(member_of_collection_presenters)
      render 'hyrax/base/relationships', presenter: presenter
    end
    it "links to work and collection" do
      expect(page).to have_link 'Containing work'
      expect(page).to have_link 'Containing collection'
    end
  end

  context "with admin sets" do
    it "renders using attribute_to_html" do
      allow(controller).to receive(:current_user).and_return(user)
      allow(solr_doc).to receive(:member_of_collection_ids).and_return([])
      allow(presenter).to receive(:grouped_presenters).and_return({})
      expect(presenter).to receive(:attribute_to_html).with(:admin_set, render_as: :faceted, html_dl: true)
      render 'hyrax/base/relationships', presenter: presenter
    end

    it "skips admin sets if user not logged in" do
      allow(controller).to receive(:current_user).and_return(nil)
      allow(presenter).to receive(:member_of_collection_presenters).and_return([])
      expect(presenter).not_to receive(:attribute_to_html).with(:admin_set, render_as: :faceted)
      render 'hyrax/base/relationships', presenter: presenter
    end
  end
end
