module ProxiesHelper
  def create_proxy_using_partial(*users)
    users.each do |user|
      sleep(0.5)
      first('a.select2-choice').click
      find(".select2-input").set(user.user_key)
      expect(page).to have_css("div.select2-result-label")
      first("div.select2-result-label").click
    end
  end

  RSpec.configure do |config|
    config.include ProxiesHelper
  end
end
