# frozen_string_literal: true
namespace :hyrax do
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

    desc 'Populate user tokens'
    task tokens: :environment do
      unless Hyrax.config.arkivo_api?
        puts "Zotero integration is not enabled"
        next
      end
      User.where(arkivo_token: nil).each do |user|
        user.set_arkivo_token
        user.save
      end
    end
  end
end
