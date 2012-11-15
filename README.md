# Scholarsphere

Run the blacklight, hydra mailboxer and scholarsphere generators
```
rails g blacklight --devise
rails g hydra:head -df
rails g mailboxer:install
rails g scholarsphere -df
```

Run the migrations

```
rake db:migrate
```

Add include Scholarsphere::User into your user model
Add include Scholarsphere::Controller into your application_controller.rb

Add role_map_*.yml files into config?


```
gem 'jettywrapper'
```
bundle install


application.css
 *= require scholarsphere

application.js
//= require scholarsphere
