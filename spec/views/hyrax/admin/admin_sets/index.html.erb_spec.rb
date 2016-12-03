describe "hyrax/admin/admin_sets/index.html.erb", type: :view do
  context "when no admin sets exists" do
    it "alerts users there are no admin sets" do
      render
      expect(rendered).to have_content("No administrative sets have been created.")
    end
  end

  context "when an admin set exists" do
    let(:admin_set) { build(:admin_set, id: '123', title: ['Example Admin Set'], creator: ['jdoe@example.com']) }
    let(:solr_doc) { SolrDocument.new(admin_set.to_solr) }
    let(:admin_sets) { [solr_doc] }
    let(:presenter_class) { Hyrax::AdminSetPresenter }
    let(:ability) { instance_double("Ability") }
    before do
      allow(controller).to receive(:current_ability).and_return(ability)
      allow(controller).to receive(:presenter_class).and_return(presenter_class)
      assign(:admin_sets, admin_sets)
    end
    it "lists admin set" do
      render
      expect(rendered).to have_content('Example Admin Set')
      expect(rendered).to have_content('jdoe@example.com')
      expect(rendered).to have_css("td", text: /^0$/)
    end
  end
end
