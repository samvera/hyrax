
describe 'hyrax/admin/admin_sets/_show_document_list_row.html.erb', type: :view do
  let(:user) { create(:user, groups: 'admin') }

  let(:work) do
    GenericWork.create(creator: ["ggm"], title: ['One Hundred Years of Solitude']) do |gw|
      gw.apply_depositor_metadata(user)
    end
  end

  before do
    view.blacklight_config = Blacklight::Configuration.new
    allow(view).to receive(:current_user).and_return(user)
    allow(work).to receive(:title_or_label).and_return("One Hundred Years of Solitude")
    allow(work).to receive(:edit_groups).and_return([user])
    allow(work).to receive(:edit_people).and_return([user])
    allow(work).to receive(:workflow_state).and_return('deposited')
    stub_template '_show_document_list_menu.erb' => 'edit menu'
  end

  it "renders works" do
    render 'hyrax/admin/admin_sets/show_document_list_row.html.erb', show_document_list_row: work
    expect(rendered).to have_content 'One Hundred Years of Solitude'
    expect(rendered).to have_content 'deposited'
  end
end
