# spec/support/features/confirmation.rb

# TODO: Delete this module when `#accept_confirm` supported by
# capybara w/ chrome:
#   https://github.com/teamcapybara/capybara/issues/1860
#   https://github.com/samvera/hyrax/issues/1445
module Features
  module Confirmation
    def accept_confirm
      page.evaluate_script('window.confirm = function() { return true; }')
      yield
    end
  end
end
