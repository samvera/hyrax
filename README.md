# Sufia

Run the blacklight, hydra and scholarsphere generators
```
rails g blacklight --devise
rails g hydra:head -f
rails g sufia -f
```

Run the migrations

```
rake db:migrate
```

In your Gemfile add this:
```
gem 'jettywrapper'
```
Then run `bundle install`


If you want to use the assets that ship with Sufia, add the following to application.css
```
 *= require scholarsphere
```
and add the following to application.js
```
//= require scholarsphere
```
