# Angular with Devise Walkthrough

When I started programming my very first Angular single page application (SPA), I noticed the resources for setup and integration with Devise to be thin or fragmented. The most useful guide I found was actually just a segmet of a general Angular with Rails walkthrough. There were other resources that were either too complex or advanced and they didn't really go through the initial baby steps. One of the most daunting challenges for a new programmer is starting from scratch. I know because I'm one of these folks. Most of what I've learned through my online course has been delivered in small components. I would open a lab, and most of the groundwork is already laid out, so there isn't a ton of practice is setting up an app from a blank slate. 

Once I finally got all the pieces working and my first Angular project was up and running, I felt it pertinant to give back to the community. Since I currently don't have enough "reputation points" to answer questions on StackOverflow, the next best thing would be to make my own walkthrough of setting up an Angular SPA on Rails with Devise and Bootstrap. The following is EXACTLY what I wish I had found in my initial resarch on the subject. 

Granted, a huge part web development is being able to solve complex problems without being handed the solution. I feel that sometimes a new developer just needs a helping hand. So here it is. 

This guide is meant to be a diving board for getting started. It assumes you already have a basic understanding of Angular, Rails, Devise, Bootstrap. I chose to not explore Active Record, however I did touch on Active Model Serializer as it is necessary for sending models to your Javascript front end. There is much more to learn about this topic and would warrant it's own series of guides. Likewise, I go into installing Bootstrap until the point that I can verify it's working.  

Feel free to read along with the video I created for this repo:

https://youtu.be/ieoxzX-VPL4

To get started, you want to open Terminal and navigate to the folder where you want to create your application. In this demonstration, I am on the Desktop.

In Terminal, you will run `$ rails new YOUR-APP` which intializes Rails, creates a directory with all the framework, and bundles all of the provided gems. In case you're unfamiliar `$` denotes a Terminal command. 

Open your `Gemfile`, remove `gem 'turbolinks'` and add the following:
```
gem 'bower-rails'
gem 'devise'
gem 'angular-rails-templates'
gem 'active-model-serializer'
gem 'bootstrap-sass', '~> 3.3.6' #=> bootstrap also requires the 'sass-rails' gem, which should already be included in your gemfile 
```

While Bower isn't essential to this project, I chose to use it for one simple reason; experience. Sooner or later, I'll probably find myself working on an app that was built with Bower so why not start playing with it now? 

What is Bower? You can learn more on their website, bower.io, but as far as I can tell, it's essentially a package manager just like ruby gems or npm. You can install it with npm, however I chose to include the `bower-rails` gem for this guide.


Now we're going to install/initialize these gems, create our database, add a migration so users can signup with a username, and then apply these migrations to our schema with the following commands:
```
$ bundle install
$ rake db:create #=> create database
$ rails g bower_rails:initialize json  #=> generates bower.json file for adding "dependencies"
$ rails g devise:install #=> generates config/initializers/devise.rb, and user resources, user model, and user migration with a TON of defualt configurations for authentication 
$ rails g migration AddUsernametoUsers username:string:uniq #=> generates, well, exactly what it says.
$ rake db:migrate
```

By the time you've got momentum building out your app, you'll likely have many more dependencies or "pagackages" but here's what you'll need to get started. Add the following vendor dependencies to `bower.json`:
```
...
"vendor": {
  "name": "bower-rails generated vendor assets",
  "dependencies": {
    "angular": "v1.5.8", 
    "angular-ui-router": "latest",
    "angular-devise": "latest"
  }
}
```



Once you've saved those changes in bower.json, you'll want to install those packages with the following command and then generate your user serializer from the 'active-model-serializer' gem installed earlierl:
```
$ rake bower:install
$ rails g serializer user
```

Look for app/serializers/user_serializer.rb and add `, :username` directly after `attributes :id` so that when Devise requests the user's information from rails, you can display their chosen username. This is much nicer than saying "Welcome, jesse@email.com" or worse, "Welcome, 5UPer$3CREtP4SSword". Just kidding, but seriously, don't do that. 



Add the following in `config/application.rb` directly under `class Application < Rails::Application`:
```
config.to_prepare do
  DeviseController.respond_to :html, :json
end
```
Since Angular will request information about the user using .json, we need to make sure the DeviseController will respond appropriately, which it doesn't do by default.

Next open `app/controllers/users_controller.rb` and make sure that you can access the user in JSON format with any `/users/:id.json` request:
```
class UsersController < ApplicationController
  def show
    user = User.find(params[:id])
    render json: user
  end  
end
```
Don't worry about setting up the `:show` resource, Devise has done this for us already!


We're getting SOOOO close to finisihing our backend. Just a few more adjustments...

Open `config/routes.rb` add the following line under `devise_for :users`:
`root 'application#index'`

Then find `app/controllers/application_controller.rb` and copy/paste this whole snippet:

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

Here, we've done a couple things. First, we're telling Rails that :json is our friend, our ONLY view lives in `views/application/index.html.erb`, don't worry about authenticity tokens when you get a call from Devise, oh and our user will have a username.


By default, Rails will intialize with `views/layouts/application.html.erb` but we don't want that, so do the following:
- MOVE that file to `app/views/application/`
- Rename it to `index.html.erb`
- Replace `<%= yield %>` with `<ui-view></ui-view>` (we won't be rendering any erb aside from the script/style tags in our header)
- add `ng-app="myApp"` as an attribute to the `<body>` tag. When we launch our server, Angular will load and frantically search our DOM for this before initializing our app. 


The final step to getting our backend configured is laying out our asset pipeline. Bower has already installed a bunch of stuff for us in `vendor/assets/bower_components` and likewise, we installed a bunch of sweet gems earlier. Let's make sure our app can find these scripts and stylesheets:

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
** don't forget to remove `require turbolinks` **

Finally, we must rename `app/assets/stylesheets/application.css` to `application.scss` and add these two `@import` lines at the end of our stylesheet:
```
*
 *= require_tree .
 *= require_self
 */
@import "bootstrap-sprockets";
@import "bootstrap";
```

Boom!! Now we have everything setup and we can start working on our front-end. 

Here's a preview of what our angular application will look like. Since we installed the 'angular-templates' gem, we can keep all of our html files in the assets/javascript directory with all of our other angular files. 
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

First thing's first, let's declare our application in `app.js` and inject the necessary dependicies:
```
(function(){
  angular
    .module('myApp', ['ui.router', 'Devise', 'templates'])
}())
```

"Wrapping your AngularJS components in an Immediately Invoked Function Expression (IIFE). This helps to prevent variables and function declarations from living longer than expected in the global scope, which also helps avoid variable collisions. This becomes even more important when your code is minified and bundled into a single file for deployment to a production server by providing variable scope for each file." - from http://www.codestyle.co/Guidelines/angularjs


Next we're going to stub out our `routes.js` file... Some of this is a step ahead of where we are now, but I'd rather get it out of the way now than come back:

```
angular
  .module('myApp')
  .config(function($stateProvider, $urlRouterProvider){
    $stateProvider
      .state('home', {
        url: '/home',
        templateUrl: 'views/home.html',
        controller: 'HomeCtrl'
      })
      .state('login', {
        url: '/login',
        templateUrl: 'views/login.html',
        controller: 'AuthCtrl',
        onEnter: function(Auth, $state){
          Auth.currentUser().then(function(){
            $state.go('home')
          })
        }
      })
      .state('register', {
        url: '/register',
        templateUrl: 'views/register.html',
        controller: 'AuthCtrl',
        onEnter: function(Auth, $state){
          Auth.currentUser().then(function(){
            $state.go('home')
          })
        }
      })
    $urlRouterProvider.otherwise('/home')
  })
```
What we've just done is called our angular app, 'myApp', and called the config function, passing in $stateProvider and $routerUrlProvider as paramters. Immediately we can call $stateProvider and start chaining `.state()` methods, which take 2 parameters, the name of the state ('home' for example), and an object of data that descrives that state, such as it's url, html template, and which controller to use. We're also using $urlRouterProvider just to make sure that the user can't navigate anywhere but to our predetermined states.

A few things probably aren't familiar with up to this point are `onEnter`, `$state`, and `Auth`. We'll get to that later. 

Now let's build out `home.html` and `HomeCtrl.js`:
```
<div class="col-lg-8 col-lg-offset-2">
<h1>{{hello}}</h1>
<h3 ng-if="user">Welcome, {{user.username}}</h3>
</div>
```

```
angular
  .module('myApp')
  .controller('HomeCtrl', function($scope, $rootScope, Auth){
    $scope.hello = "Hello World"
  })
```

You may want to comment the login/register states and run `$ rails s` to make sure everything is working. If it is you'll see a big beautiful "Hello World". If it's right at the top towards the middle, take a big breath of relief because Bootstrap is kicking in and that `col-lg` stuff is positioning it nicely rather than being stuck in the top left corner. 

What Angular has done is searched the DOM, found the attribute `ng-app`, initialized "myApp", navigated to `/home` by default from our router, located the `<ui-view>` directive, instantiated our `HomeCtrl`, injected the `$scope` object, added an key of `hello` with a value of `"Hello World"` to this object, and then rendered `home.html` with this information into the `<ui-view>` element. Once in the view, Angular scans for anything meaningful commands such as the `{{...}}` bindings and the `ng-if` directive and renders the controllers information as appropriate. I will admit the order of these operations may be off slightly but you get the jist. 


Since we've got all of this nitty gritty behind the scense information out of the way, let's build out our `AuthCtrl.js` and `login.html`/`register.html` files:

```
<div class="col-lg-8 col-lg-offset-2">
  <h1 class="centered-text">Log In</h1>
  <form ng-submit="login()">
    <div class="form-group">
      <input type="email" class="form-control" placeholder="Email" ng-model="user.email" autofocus>
    </div>
    <div class="form-group">
      <input type="password" class="form-control" placeholder="Password" ng-model="user.password">
    </div>
    <input type="submit" class="btn btn-info" value="Log In">
  </form>
</div>
```

```
<div class="col-lg-8 col-lg-offset-2">
  <h1 class="centered-text">Register</h1>
  <form ng-submit="register()">
    <div class="form-group">
      <input type="email" class="form-control" placeholder="Email" ng-model="user.email" autofocus>
    </div>
    <div class="form-group">
      <input type="username" class="form-control" placeholder="Username" ng-model="user.username" autofocus>
    </div>
    <div class="form-group">
      <input type="password" class="form-control" placeholder="Password" ng-model="user.password">
    </div>
    <input type="submit" class="btn btn-info" value="Log In">
  </form>
  <br>

  <div class="panel-footer">
    Already signed up? <a ui-sref="home.login">Log in here</a>.
  </div>
</div>
```

Before I overwhelm you with the AuthCtrl, I just want to point out that most of what you're seeing is Bootstraped CSS so that you're all super impressed with how beautfully this renders. Ignore all of the class atributes, and everything else should be pretty familiar, such as `ng-submit`, `ng-model`, and `ui-sref`, which takes the places of our usual `href` a-tag attribute. Now for the AuthCtrl... are you ready?

```
angular
  .module('myApp')
  .controller('AuthCtrl', function($scope, $rootScope, Auth, $state){
    var config = {headers: {'X-HTTP-Method-Override': 'POST'}}

    $scope.register = function(){
      Auth.register($scope.user, config).then(function(user){
        $rootScope.user = user
        alert("Thanks for signing up, " + user.username);
        $state.go('home');
      }, function(response){
        alert(response.data.error)
      });
    };

    $scope.login = function(){
      Auth.login($scope.user, config).then(function(user){
        $rootScope.user = user
        alert("You're all signed in, " + user.username);
        $state.go('home');
      }, function(response){
        alert(response.data.error)
      });
    }
  })
```  

Most of this code is derived from the Angular Devise documentation (https://github.com/cloudspace/angular_devise), so I won't go into too much detail. What you need to know now is that `Auth`, is thee service created by `angular-device` and it comes with some pretty awesome functions, such as `Auth.login(userParameters, config)` and `Auth.register(userParameters, config)`. These create a promise, which returns the logged in user once resolved. I will admit that I've cheated a bit here and assinged that user to the `$rootScope`, however a better performing, more scalable approach would be to create a UserService, store it there, and then inject UserService into any of your controllers that need the user. For the sake of brevity, I also used a simple `alert()` function in leiu of integrating `ngMessages` or another service like `ngFlash` to make announcements about errors or 

The rest should be pretty self explainatory, the `ng-submit` forms are attached to these `$scope` functions, `$scope.user` is pulling the infomration from the `ng-model`s on the form inputs, and `$state.go()` is a nifty function for redirecting to another state.

If you go back to `routes.js` now, all of that `onEnter` logic should make a lot more sense. 

And of course I saved the best for last, so let's build a fancy little `NavDirective.js` and `nav.html` to bring everything together:
```
angular
  .module('myApp')
  .directive('navBar', function NavBar(){
    return {
      templateUrl: 'views/nav.html',
      controller: 'NavCtrl'
    }
})
```

```
<div class="col-lg-8 col-lg-offset-2">
  <ul class="nav navbar-nav" >
    <li><a ui-sref="home">Home</a></li>
    <li ng-hide="signedIn()"><a ui-sref="login">Login</a></li>
    <li ng-hide="signedIn()"><a ui-sref="register">Register</a></li>
    <li ng-show="signedIn()"><a ng-click="logout()">Log Out</a></li>
  </ul>
</div>
```

And the more robust `NavCtrl.js`:
```
angular
  .module('myApp')
  .controller('NavCtrl', function($scope, Auth, $rootScope){
    $scope.signedIn = Auth.isAuthenticated;
    $scope.logout = Auth.logout;

    Auth.currentUser().then(function (user){
      $rootScope.user = user
    });

    $scope.$on('devise:new-registration', function (e, user){
      $rootScope.user = user
    });

    $scope.$on('devise:login', function (e, user){
      $rootScope.user = user
    });

    $scope.$on('devise:logout', function (e, user){
      alert("You have been logged out.")
      $rootScope.user = undefined
    });
  })
```

All we're doing here is setting up the functions to use in the navigation links such as `ng-hide="signedIn()"` and `ng-clic="logout()"` and adding a listeners to the `$scope` so that we can trigger certain actions when certain `devise` specific events occur. We're also calling `Auth.currentuser()` so that when this controller is instantiated, we can verify our `$rootScope.user` object and display the proper nav links.

Let's find `app/views/application/index.html` again and add `<nav-bar></nav-bar>` on the line about `<ui-view>`. Since this isn't tied to any of the routes, it will always render above our main content.

Go ahead and refresh your page now. Don't you love it when things just work? Hopefully you don't have some issues with an out of date bundle or version of Ruby. Just remember, Google is your best friend. 

Please leave comments with questions, comments, or suggestions!