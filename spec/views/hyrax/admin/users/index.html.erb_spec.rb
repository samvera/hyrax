# frozen_string_literal: true
RSpec.describe 'hyrax/admin/users/index.html.erb', type: :view do
  let(:presenter) { Hyrax::Admin::UsersPresenter.new }
  let(:users) { [] }

  before do
    (1..4).each { |i| users << build(:user, display_name: "user#{i}", email: "email#{i}@example.com", created_at: Time.zone.now - 3.days) }
    allow(presenter).to receive(:users).and_return(users)
    assign(:presenter, presenter)
    allow(presenter).to receive(:show_last_access?).and_return(show_last_access)
  end

  let(:page) do
    render
    Capybara::Node::Simple.new(rendered)
  end

  context 'when show_last_access? is true' do
    let(:show_last_access) { true }
    before do
      allow(presenter).to receive(:last_accessed).and_return(Time.zone.now - 3.days)
    end

    it 'draws user list with all users' do
      expect(page).to have_content("Username")
      expect(page).to have_content("Roles")
      expect(page).to have_content("Last access")
      (1..4).each do |i|
        expect(page).to have_content("email#{i}@example.com")
      end
    end
  end

  context 'when show_last_access? is false' do
    let(:show_last_access) { false }

    it 'draws user list with all users' do
      expect(page).to have_content("Username")
      expect(page).to have_content("Roles")
      expect(page).not_to have_content("Last access")
      (1..4).each do |i|
        expect(page).to have_content("email#{i}@example.com")
      end
    end
  end
end
