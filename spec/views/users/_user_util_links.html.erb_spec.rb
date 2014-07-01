require 'spec_helper'

describe '/_user_util_links.html.erb' do

  let(:join_date) { 5.days.ago }
  before do
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(stub_model(User, user_key: 'userX'))
    assign :notify_number, 8
  end

  it 'should have link to dashboard' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_link('userX', href: '/dashboard')
  end

  it 'should have link to user profile' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_link('my profile', href: '/users/userX')
  end

end

