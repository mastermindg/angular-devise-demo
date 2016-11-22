# Angular with Devise Walkthrough

For this blog post, I have decided to create a video walkthrough of how to create an Angular application with Devise for basic authentication. 

Getting started on my Angular portfolio project, this was one of the my biggest hurdles. Online resources were sparce, incomplete, or overwhelming, so I decided to create a guide.

The link can be found here: https://youtu.be/ieoxzX-VPL4

Here are the steps I took:

Run `$ rails new YOUR-APP` in Terminal to get started...

Add the following to your `Gemfile`:
```
gem 'bower-rails'
gem 'devise'
gem 'angular-rails-templates'
gem 'active-model-serializer'
gem 'bootstrap-sass', '~> 3.3.6'
* remove turbolinks gem
```

In Terminal run:
```
$ rake db:create
$ rails g bower_rails:initialize json
$ rails g devise:install
$ rails g migration AddUsernametoUsers username:string:uniq
$ rake db:migrate
```

Add the following vendor dependencies to `bower.json`:
```
"angular": "v1.5.8"
"angular-ui-router": "latest"
"angular-devise": "latest"
```

Then a few more commands in Terminal:
```
$ bundle install
$ rake bower:install
$ rails g serializer user
```

Add `:username` to `app/serializers/user_serializer.rb`

In `config/routes.rb` add `root 'application#index'`

Move `views/layouts/application.html.erb` to `app/views/application/`, rename it to `index.html.erb`, and replace `<%= yield %>` with `<ui-view></ui-view>`.

Add the following in `config/application.rb` directly under `class Application < Rails::Application`:
```
config.to_prepare do
  DeviseController.respond_to :html, :json
end
```

#app/controllers/application_controller.rb
```
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  skip_before_action :verify_authenticity_token

  respond_to :json

  def index
    render 'application/index'
  end

  protected

  def configure_permitted_parameters
    added_attrs = [:username, :email, :password, :password_confirmation, :remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end
end
```

#app/controllers/users_controller.rb
```
def show
  user = User.find(params[:id])
  render json: user
end
```

Require the following in `app/assets/javascript/application.js`:
```
//= require jquery
//= require jquery_ujs
//= require angular
//= require angular-ui-router
//= require angular-devise
//= require angular-rails-templates
//= require bootstrap-sprockets
//= require_tree .
```

Rename `app/assets/stylesheets/application.css` to `application.scss` and add
```
*
 *= require_tree .
 *= require_self
 */
@import "bootstrap-sprockets";
@import "bootstrap";
```

Now stub out your Angular tree:
```
/javascript/controllers/AuthCtrl.js
/javascript/controllers/HomeCtrl.js
/javascript/controllers/NavCtrl.js
/javascript/directives/NavDirective.js
/javascript/views/home.html
/javascript/views/login.html
/javascript/views/register.html
/javascript/views/nav.html
/javascript/app.js
/javascript/routes.js
```

Reference these files in reference to the video.