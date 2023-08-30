# frozen_string_literal: true
RSpec.describe 'hyrax/base/_show_actions.html.erb', type: :view do
  let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, ability) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) { { "has_model_ssim" => ["GenericWork"], :id => "0r967372b" } }
  let(:ability) { double }
  let(:member) { Hyrax::WorkShowPresenter.new(member_document, ability) }
  let(:member_document) { SolrDocument.new(member_attributes) }
  let(:member_attributes) { { "has_model_ssim" => ["GenericWork"], :id => "8336h190k" } }

  before do
    allow(ability).to receive(:can?).with(:create, FeaturedWork).and_return(false)
    allow(view).to receive(:workflow_restriction?).and_return(false)
  end

  context "as an unregistered user" do
    before do
      allow(presenter).to receive(:show_deposit_for?).with(anything).and_return(false)
      allow(presenter).to receive(:editor?).and_return(false)
      render 'hyrax/base/show_actions', presenter: presenter
    end
    it "doesn't show edit / delete / Add to collection links" do
      expect(rendered).not_to have_link 'Edit'
      expect(rendered).not_to have_link 'Delete'
      expect(rendered).not_to have_link 'Add to collection'
    end
  end

  context "as an editor" do
    before do
      allow(presenter).to receive(:show_deposit_for?).with(anything).and_return(true)
      allow(presenter).to receive(:editor?).and_return(true)
    end

    context "when the work does not contain children" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([].to_enum)
      end

      it "does not show file manager link" do
        render 'hyrax/base/show_actions', presenter: presenter

        expect(rendered).not_to have_link 'File Manager'
      end

      it "shows edit / delete / Add to collection links" do
        render 'hyrax/base/show_actions', presenter: presenter

        expect(rendered).to have_link 'Edit'
        expect(rendered).to have_link 'Delete'
        expect(rendered).to have_button 'Add to collection'
      end
    end

    context "when the work contains 1 child" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([member].to_enum)
      end

      it "does not show file manager link" do
        render 'hyrax/base/show_actions', presenter: presenter
        expect(rendered).not_to have_link 'File Manager'
      end
    end

    context "when the work contains 2 children" do
      let(:file_member) { Hyrax::FileSetPresenter.new(file_document, ability) }
      let(:file_document) { SolrDocument.new(file_attributes) }
      let(:file_attributes) { { id: '1234' } }

      before do
        allow(presenter).to receive(:member_presenters).and_return([member, file_member].to_enum)
      end

      it "shows file manager link" do
        render 'hyrax/base/show_actions', presenter: presenter
        expect(rendered).to have_link 'File Manager'
      end
    end

    context "when there are valid_child_concerns" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([])
        render 'hyrax/base/show_actions', presenter: presenter
      end
      it "creates a link to add child work" do
        expect(rendered).to have_button 'Attach Child'

        within('button#dropdown-menu') do
          expect(rendered).to have_link 'Attach Generic Work', href: "/concern/parent/#{presenter.id}/generic_works/new"
        end
      end
    end
  end

  context "when user CAN deposit to at least one collection" do
    before do
      allow(presenter).to receive(:show_deposit_for?).with(anything).and_return(true)
      allow(presenter).to receive(:member_presenters).and_return([])
    end

    context "and user is editor" do
      before do
        allow(presenter).to receive(:editor?).and_return(true)
        render 'hyrax/base/show_actions', presenter: presenter
      end

      it "shows editor related buttons" do
        expect(rendered).not_to have_link 'File Manager'
        expect(rendered).to have_link 'Edit'
        expect(rendered).to have_link 'Delete'
        expect(rendered).to have_button 'Add to collection'
      end
    end

    context "and user is viewer" do
      before do
        allow(presenter).to receive(:editor?).and_return(false)
        render 'hyrax/base/show_actions', presenter: presenter
      end
      it "shows only Add to collection link" do
        expect(rendered).not_to have_link 'File Manager'
        expect(rendered).not_to have_link 'Edit'
        expect(rendered).not_to have_link 'Delete'
        expect(rendered).to have_button 'Add to collection'
      end
    end
  end

  context "when user can NOT deposit to any collections" do
    before do
      allow(presenter).to receive(:show_deposit_for?).with(anything).and_return(false)
      allow(presenter).to receive(:member_presenters).and_return([])
    end

    context "and user is editor" do
      before do
        allow(presenter).to receive(:editor?).and_return(true)
        render 'hyrax/base/show_actions', presenter: presenter
      end

      it "shows editor related buttons" do
        expect(rendered).not_to have_link 'File Manager'
        expect(rendered).to have_link 'Edit'
        expect(rendered).to have_link 'Delete'
        expect(rendered).not_to have_button 'Add to collection'
      end
    end

    context "and user is viewer" do
      before do
        allow(presenter).to receive(:editor?).and_return(false)
        render 'hyrax/base/show_actions', presenter: presenter
      end

      it "shows only Add to collection link" do
        expect(rendered).not_to have_link 'File Manager'
        expect(rendered).not_to have_link 'Edit'
        expect(rendered).not_to have_link 'Delete'
        expect(rendered).not_to have_button 'Add to collection'
      end
    end
  end
end
