# frozen_string_literal: true
json.users @users do |user|
  json.id user.id
  json.user_key user.user_key
  json.text user.to_s
end
