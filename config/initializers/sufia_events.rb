Sufia.config.after_create_content = lambda {|generic_file, user|
  Sufia.queue.push(ContentDepositEventJob.new(generic_file.pid, user.user_key))
}