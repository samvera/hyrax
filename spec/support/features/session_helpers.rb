# spec/support/features/session_helpers.rb
module Features
  module SessionHelpers
    def sign_in(who = :user)
      logout
      user = who.is_a?(User) ? who : FactoryBot.build(:user).tap(&:save!)
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Log in'
      expect(page).not_to have_text 'Invalid email or password.'
    end
  end
end
