# frozen_string_literal: true
RSpec.describe 'hyrax/admin/admin_sets/_show_actions.html.erb', type: :view do
  let(:solr_document) { SolrDocument.new }
  let(:ability) { instance_double("Ability") }
  let(:presenter) { Hyrax::AdminSetPresenter.new(solr_document, ability) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(view).to receive(:presenter).and_return(presenter)

    # Stub route because view specs don't handle engine routes
    allow(view).to receive(:edit_admin_admin_set_path).with(presenter).and_return("/admin/admin_sets/123/edit")
    allow(view).to receive(:admin_admin_set_path).with(presenter).and_return("/admin/admin_sets/123")
  end

  context 'when editor of the admin_set' do
    before do
      allow(ability).to receive(:can?).with(:edit, solr_document).and_return(true)
    end

    context "when presenter has delete disabled" do
      before do
        allow(presenter).to receive(:disable_delete?).and_return(true)
        allow(presenter).to receive(:disabled_message).and_return('')
        render
      end
      it "displays a disabled delete button" do
        expect(rendered).to have_selector(:css, "a.btn-danger.disabled")
        expect(rendered).to have_selector(:css, "a.btn-primary")
      end
    end

    context "with empty admin set" do
      before do
        allow(presenter).to receive(:disable_delete?).and_return(false)
        render
      end
      it "displays an enabled delete button" do
        expect(rendered).to have_selector(:css, "a.btn-danger")
        expect(rendered).not_to have_selector(:css, "a.btn-danger.disabled")
        expect(rendered).to have_selector(:css, "a.btn-primary")
      end
    end

    context "with default admin set" do
      before do
        allow(presenter).to receive(:disable_delete?).and_return(true)
        allow(presenter).to receive(:disabled_message).and_return('')
        render
      end
      it "displays a disabled delete button" do
        expect(rendered).to have_selector(:css, "a.btn-danger.disabled")
        expect(rendered).to have_selector(:css, "a.btn-primary")
      end
    end
  end

  context 'when reader of the admin_set' do
    before do
      allow(ability).to receive(:can?).with(:edit, solr_document).and_return(false)
      render
    end

    it "doesn't display any action buttons" do
      expect(rendered).not_to have_selector(:css, "a.btn-danger")
      expect(rendered).not_to have_selector(:css, "a.btn-primary")
    end

    it "displays the admin_set title" do
      expect(rendered).to have_selector(:css, "h2.card-title")
    end
  end
end
