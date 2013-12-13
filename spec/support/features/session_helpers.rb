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
      if who.instance_of?(User)
        user = who
      else
        user = FactoryGirl.find_or_create(who)
        if user.password.nil?   # get the password from the factory if user was retrieved from database
          tmpl = FactoryGirl.build(who)
          user.password = tmpl.password
        end
      end
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Sign in'
    end
  end
end
