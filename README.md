# Sufia
## Creating an application
### Generate base Rails install
```rails new my_app```
### Add gems to Gemfile
```
gem 'blacklight'
gem 'hydra-head'
gem 'sufia'
gem 'jettywrapper'
```
Then `bundle install`

### Run the blacklight, hydra and scholarsphere generators
```
rails g blacklight --devise
rails g hydra:head -f
rails g sufia -f
```

### Run the migrations

```
rake db:migrate
```


###If you want to use the assets that ship with Sufia, add the following to application.css
```
 *= require scholarsphere
```
and add the following to application.js
```
//= require scholarsphere
```

## Developers:
This information is for people who want to modify the engine itself, not an application that uses the engine:
### Create fixtures
```
rake sufia:fixtures:create sufia:fixtures:generate
rake fixtures
rake clean spec
bundle exec cucumber fixtures
```
