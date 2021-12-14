((nil . ((rspec-use-docker-when-possible . t)
         (rspec-docker-wrapper-fn . (lambda (rspec-docker-command rspec-docker-container command) (format "%s -w /app/samvera/hyrax-engine %s sh -c \"%s\"" rspec-docker-command rspec-docker-container command)))
         (rspec-docker-cwd . "/app/samvera/hyrax-engine/")
         (rspec-docker-container . "app"))))
