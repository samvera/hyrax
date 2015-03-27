Sufia.config.after_create_content = lambda { |generic_file, user|
  Sufia.queue.push(ContentDepositEventJob.new(generic_file.id, user.user_key))
}

Sufia.config.after_revert_content = lambda { |generic_file, user, revision|
  Sufia.queue.push(ContentRestoredVersionEventJob.new(generic_file.id, user.user_key, revision))
}

Sufia.config.after_update_content = lambda { |generic_file, user|
  Sufia.queue.push(ContentNewVersionEventJob.new(generic_file.id, user.user_key))
}

Sufia.config.after_update_metadata = lambda { |generic_file, user|
  Sufia.queue.push(ContentUpdateEventJob.new(generic_file.id, user.user_key))
}

Sufia.config.after_destroy = lambda { |id, user|
  Sufia.queue.push(ContentDeleteEventJob.new(id, user.user_key))
}
