# spec/support/features/session_helpers.rb
module Features
  module SessionHelpers
    def sign_up_with(email, password)
      Capybara.exact = true
      visit new_user_registration_path
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      fill_in 'Password confirmation', with: password
      click_button 'Sign up'
    end

    def sign_in(who = :user)
      user = if who.instance_of?(User)
        who
      else
        FactoryGirl.build(:user).tap do |u|
          u.save!
        end
      end
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Log in'
      expect(page).to_not have_text 'Invalid email or password.'
    end
  end
end
