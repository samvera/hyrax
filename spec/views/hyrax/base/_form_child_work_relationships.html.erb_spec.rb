RSpec.describe "hyrax/base/_form_child_work_relationships.html.erb", type: :view do
  let(:work) do
    stub_model(GenericWork, id: '456', title: ["MyWork"])
  end

  let(:change_set) do
    GenericWorkChangeSet.new(work)
  end

  let(:f) do
    view.simple_form_for(change_set, url: '/update') do |cs|
      return cs
    end
  end

  before do
    allow(view).to receive(:params).and_return(id: work.id)
    allow(view).to receive(:curation_concern).and_return(work)
    allow(view).to receive(:f).and_return(f)
    allow(f).to receive(:object).and_return(change_set)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:change_set, change_set)
  end

  context "When editing a work" do
    context "and no children works are present" do
      before do
        allow(change_set).to receive(:work_members).and_return([])
        render
      end

      it "draws the page" do
        # remove button is not present
        expect(rendered).not_to have_selector("[data-behavior='remove-relationship']")

        # input with add button
        expect(rendered).to have_selector('input[data-autocomplete-url="/authorities/search/find_works"]')
        expect(rendered).to have_selector("[data-behavior='add-relationship']")
      end
    end

    context "and child works are present" do
      before do
        allow(change_set).to receive(:work_members_json).and_return('stub-data')
        render
      end

      it "draws the page" do
        # input with add button
        expect(rendered).to have_selector('input[data-autocomplete-url="/authorities/search/find_works"]')
        expect(rendered).to have_selector("[data-behavior='add-relationship']")

        # generate the json to drive the script
        expect(rendered).to have_selector('div[data-members="stub-data"]')

        # a remove button
        within "tr" do
          expect(rendered).to have_selector("[data-behavior='remove-relationship']")
        end
      end
    end
  end
end
