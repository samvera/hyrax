CurationConcerns.config.after_create_content = lambda { |generic_file, user|
  CurationConcerns.queue.push(ContentDepositEventJob.new(generic_file.id, user.user_key))
}

CurationConcerns.config.after_revert_content = lambda { |generic_file, user, revision|
  CurationConcerns.queue.push(ContentRestoredVersionEventJob.new(generic_file.id, user.user_key, revision))
}

CurationConcerns.config.after_update_content = lambda { |generic_file, user|
  CurationConcerns.queue.push(ContentNewVersionEventJob.new(generic_file.id, user.user_key))
}

CurationConcerns.config.after_update_metadata = lambda { |generic_file, user|
  CurationConcerns.queue.push(ContentUpdateEventJob.new(generic_file.id, user.user_key))
}

CurationConcerns.config.after_destroy = lambda { |id, user|
  CurationConcerns.queue.push(ContentDeleteEventJob.new(id, user.user_key))
}
