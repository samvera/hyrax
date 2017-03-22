
describe 'hyrax/admin/admin_sets/_show_document_list.html.erb', type: :view do
  let(:user) { create(:user, groups: 'admin') }

  let(:work) do
    GenericWork.create(creator: ["ggm"], title: ['One Hundred Years of Solitude']) do |gw|
      gw.apply_depositor_metadata(user)
    end
  end

  let(:documents) { [work] }

  before do
    view.blacklight_config = Blacklight::Configuration.new
    allow(view).to receive(:current_user).and_return(user)
    allow(work).to receive(:title_or_label).and_return("One Hundred Years of Solitude")
    allow(work).to receive(:edit_groups).and_return([user])
    allow(work).to receive(:edit_people).and_return([user])
    allow(work).to receive(:workflow_state).and_return('deposited')
    stub_template '_show_document_list_menu.erb' => ''
  end

  it "renders rows of works" do
    render('hyrax/admin/admin_sets/show_document_list.html.erb', documents: documents)
    expect(rendered).to have_content 'One Hundred Years of Solitude'
  end
end
