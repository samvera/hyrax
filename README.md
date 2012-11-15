# Scholarsphere

Add to config/routes.rb
```
  mount Scholarsphere::Engine => '/'
```


Run the blacklight generator
```
rails generate blacklight --devise
```

Run the scholarsphere migrations
how?

```
rake db:migrate
```

Add include Scholarsphere::User into your user model
Add include Scholarsphere::Controller into your application_controller.rb

run the mailboxer generator


```
gem 'jettywrapper'
```
bundle install


Edit the config/solr.yml so that it had dev/test cores
