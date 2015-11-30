namespace :sufia do
  namespace :user do
    desc "list user's email"
    task "list_emails", [:file_name] => :environment do |_cmd, args|
      file_name = args[:file_name]
      file_name ||= "user_emails.txt"
      users = User.all.map(&:email).reject(&:blank?)
      f = File.new(file_name, "w")
      f.write(users.join(", "))
      f.close
    end
  end
end
