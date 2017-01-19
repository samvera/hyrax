json.users @users do |user|
  json.id user.id
  json.text user.to_s
end
