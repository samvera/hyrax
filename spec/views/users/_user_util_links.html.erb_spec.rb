require 'spec_helper'

describe '/_user_util_links.html.erb', type: :view do
  let(:join_date) { 5.days.ago }
  before do
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(stub_model(User, user_key: 'userX'))
    allow(view).to receive(:can?).with(:create, GenericWork).and_return(can_create_file)
    assign :notify_number, 8
  end

  let(:can_create_file) { true }

  it 'has link to user profile' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_link 'userX', href: '/users/userX'
  end
end
