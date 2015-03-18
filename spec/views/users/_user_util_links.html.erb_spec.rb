require 'spec_helper'

describe '/_user_util_links.html.erb', :type => :view do

  let(:join_date) { 5.days.ago }
  before do
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(stub_model(User, user_key: 'userX'))
    allow(view).to receive(:can?).with(:create, GenericFile).and_return(can_create_file)
    assign :notify_number, 8
  end

  let(:can_create_file) { true }

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

  describe "upload button" do
    before do
      render
    end
    context "when the user can create generic files" do
      it "should have a link to upload" do
        expect(rendered).to have_link('upload', href: '/files/new')
      end
    end
    context "when the user can't create generic files" do
      let(:can_create_file) { false }
      it "should not have a link to upload" do
        expect(rendered).not_to have_link('upload')
      end
    end
  end

end

