# frozen_string_literal: true
RSpec.describe 'hyrax/base/relationships', type: :view do
  let(:ability) { Ability.new(user) }
  let(:member_of_collection_presenters) { [] }
  let(:presenter) { Hyrax::WorkShowPresenter.new(solr_doc, ability) }
  let(:user) { FactoryBot.create(:user, groups: 'admin') }

  before do
    # login, more or less
    allow(controller).to receive(:current_user).and_return user

    allow(presenter)
      .to receive(:member_of_collection_presenters)
      .and_return(member_of_collection_presenters)
  end

  let(:solr_doc) do
    SolrDocument.new(id: '123',
                     human_readable_type: 'Work',
                     admin_set: nil)
  end

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
        has_model_ssim: [Hyrax.config.collection_model],
        title_tesim: ['Containing collection']
      ),
      ability
    )
  end

  let(:page) { Capybara::Node::Simple.new(rendered) }

  context "when collections are present and no parents are present" do
    let(:member_of_collection_presenters) { [collection] }

    it "links to collections" do
      render 'hyrax/base/relationships', presenter: presenter

      expect(page).to have_text 'In Collection'
      expect(page).to have_link 'Containing collection'
      expect(page).not_to have_text 'In Generic work'
    end
  end

  context "when parents are present and no collections are present" do
    let(:member_of_collection_presenters) { [generic_work] }

    it "links to work" do
      render 'hyrax/base/relationships', presenter: presenter

      expect(page).to have_text 'In Generic work'
      expect(page).to have_link 'Containing work'
      expect(page).not_to have_text 'In Collection'
    end
  end

  context "when parents are present and collections are present" do
    let(:member_of_collection_presenters) { [generic_work, collection] }

    it "links to work and collection" do
      render 'hyrax/base/relationships', presenter: presenter

      expect(page).to have_link 'Containing work'
      expect(page).to have_link 'Containing collection'
    end
  end

  context "with admin sets" do
    it "renders using attribute_to_html" do
      expect(presenter)
        .to receive(:attribute_to_html)
        .with(:admin_set, render_as: :faceted, html_dl: true)

      render 'hyrax/base/relationships', presenter: presenter
    end

    context 'and logged out' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it "skips admin sets" do
        expect(presenter)
          .not_to receive(:attribute_to_html)
          .with(:admin_set, render_as: :faceted)

        render 'hyrax/base/relationships', presenter: presenter
      end
    end
  end
end
