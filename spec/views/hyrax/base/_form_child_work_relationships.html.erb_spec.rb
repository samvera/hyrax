require 'spec_helper'

RSpec.describe "hyrax/base/_form_child_work_relationships.html.erb", type: :view do
  let(:work) do
    stub_model(GenericWork, id: '456', title: ["MyWork"])
  end

  let(:ability) { double }

  let(:form) do
    Hyrax::Forms::WorkForm.new(work, ability, controller)
  end

  let(:f) do
    view.simple_form_for(form, url: '/update') do |work_form|
      return work_form
    end
  end

  let(:page) do
    render
    Capybara::Node::Simple.new(rendered)
  end

  before do
    allow(view).to receive(:params).and_return(id: work.id)
    allow(view).to receive(:curation_concern).and_return(work)
    allow(view).to receive(:f).and_return(f)
    allow(f).to receive(:object).and_return(form)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    stub_template '_find_work_widget.html.erb' => "<input class='finder'/>"
    assign(:form, form)
  end

  context "When editing a work" do
    context "and no children works are present" do
      before do
        allow(form).to receive(:work_members).and_return([])
      end

      it "draws the page" do
        # remove button is not present
        expect(page).not_to have_selector("[data-behavior='remove-relationship']")

        # input with add button
        expect(page).to have_selector("input.finder")
        expect(page).to have_selector("[data-behavior='add-relationship']")
      end
    end

    context "and child works are present" do
      let(:work_2) do
        stub_model(GenericWork, id: '567', title: ["Test Child Work"])
      end

      before do
        allow(form).to receive(:work_members).and_return([work_2])
      end

      it "draws the page" do
        # input with add button
        expect(page).to have_selector("input.finder")
        expect(page).to have_selector("[data-behavior='add-relationship']")

        # an input box that is filled in with the child id
        expect(page).to have_selector("input[value='#{work_2.id}']", visible: false)

        # generate a link for the child work's title
        expect(page).to have_link("Test Child Work")

        # a remove button
        within "tr" do
          expect(page).to have_selector("[data-behavior='remove-relationship']")
        end
      end
    end
  end
end
