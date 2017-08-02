# Angular with Devise Walkthrough


When I started programming my very first Angular single page application (SPA), I noticed the resources for setup and integration with Devise to be thin or fragmented. The most useful guide I found was actually just a segment of a general Angular with Rails walkthrough. There were other resources that were either too complex or advanced and they didn't really go through the initial baby steps. One of the most daunting challenges for a new programmer is starting from scratch. I know because I'm one of these folks. 


Most of what I've learned through my online course has been delivered in small, increasingly more advanced components. I would open a lab, and the groundwork is already laid out, so there isn't a ton of practice in setting up an app from a blank slate. For the sake of course completion time, this makes sense. Besides, you only need to build a couple apps from the ground up to get a feel for how it’s done. If you haven’t gotten there yet, this is walkthrough will be right up your alley. 


Once I finally got all the pieces working and my first Angular project was up and running, I felt it pertinent to give back to the community. Since I currently don't have enough "reputation points" to answer questions on StackOverflow, the next best thing would be to make my own walkthrough for setting up an Angular SPA on Rails with Devise and Bootstrap. The following is EXACTLY what I wish I had found in my initial research on the topic. 


Granted, a huge part of web development is being able to solve complex problems without being handed the solution. I feel that sometimes a new developer just needs a helping hand. So here it is. 


This guide is meant to be a diving board for getting started. It assumes you already have a basic understanding of Angular, Rails, Devise, and Bootstrap. I chose to not explore Active Record, however I do touch on Active Model Serializer as it is necessary for sending models to your Javascript front end. There is much more to learn about this subject and would warrant it's own series of guides. Likewise, I only go into installing Bootstrap until the point that I can verify it's working.  



## Quick Start

Build and run the completed project with Docker:

```
docker build -t angular-devise-demo .
docker run -d --name angular -p 3000:3000 angular-devise-demo
```

Go to http://localhost:3000 to check out the site!

## Build from sratch

Feel free to read along with the video I created for this repo:
https://youtu.be/CtsC0iRxrAk

To get started, you want to open Terminal and navigate to the folder where you want to create your new application. In this demonstration, I am on the Desktop.


In Terminal, you will run `$ rails new YOUR-APP` which initializes Rails, creates a directory with the entire framework, and bundles all of the baked in gems. In case you're unfamiliar, `$` denotes a Terminal command. 


Open your `Gemfile`, remove `gem 'turbolinks'` and add the following:
```
gem 'bower-rails'
gem 'devise'
gem 'angular-rails-templates' #=> allows us to place our html views in the assets/javascript directory
gem 'active_model_serializers'
gem 'bootstrap-sass', '~> 3.3.6' #=> bootstrap also requires the 'sass-rails' gem, which should already be included in your gemfile 
```


While Bower isn't essential to this project, I chose to use it for one simple reason; experience. Sooner or later, I'll probably find myself working on an app that was built with Bower so why not start playing with it now? 


What is Bower? You can learn more on their website, bower.io, but as far as I can tell, it's essentially a package manager just like ruby gems or npm. You can install it with npm, however I chose to include the `bower-rails` gem for this guide.




Now we're going to install/initialize these gems, create our database, add a migration so users can signup with a username, and then apply these migrations to our schema with the following commands:
```
$ bundle install
$ rake db:create #=> create database
$ rails g bower_rails:initialize json  #=> generates bower.json file for adding "dependencies"
$ rails g devise:install #=> generates config/initializers/devise.rb, user resources, user model, and user migration with a TON of default configurations for authentication 
$ rails g migration AddUsernametoUsers username:string:uniq #=> generates, well, exactly what it says.
$ rake db:migrate
```


By the time you've got momentum building out your app, you'll likely have many more dependencies or "packages" but here's what you'll need to get started. Add the following vendor dependencies to `bower.json`:
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






Once you've saved those changes in bower.json, you'll want to install those packages with the following command and then generate your user serializer from the 'active-model-serializer' gem installed earlier:
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
Since Angular will request information about the user using `.json`, we need to make sure the DeviseController will respond appropriately, which it doesn't do by default.




We're getting SOOOO close to finishing our back-end. Just a few more adjustments...


Open `config/routes.rb` and add the following line under `devise_for :users`:
`root 'application#index'`


Then replace the contents of `app/controllers/application_controller.rb` with this whole snippet:


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


We’ve done a few things here. First, we're telling Rails that `:json` is our friend, our ONLY view lives in `views/application/index.html.erb`, don't worry about authenticity tokens when you get a call from Devise, oh and our user will have a username.


Next open `app/controllers/users_controller.rb` and make sure that you can access the user in JSON format with any `/users/:id.json` request:
```
class UsersController < ApplicationController
  def show
    user = User.find(params[:id])
    render json: user
  end  
end
```
Don't worry about setting up the `:show` resource in `routes.rb`, Devise has done this for us already!


By default, Rails will initialize with `views/layouts/application.html.erb` but we don't want that (or rather, I don’t want this), so do the following:
- MOVE that file to `app/views/application/`
- Rename it to `index.html.erb`
- Replace `<%= yield %>` with `<ui-view></ui-view>` (we won't be rendering any erb aside from the script/style tags in our header)
- Remove any mention of "turoblinks" in the script and stylesheet erb tags
- add `ng-app="myApp"` as an attribute to the `<body>` tag. When we launch our server, Angular will load and frantically search our DOM for this before initializing our app. 




The final step to getting our back-end configured is laying out our asset pipeline. Bower has already installed a bunch of stuff for us in `vendor/assets/bower_components` and likewise, we installed a bunch of sweet gems earlier. Let's make sure our app can find these scripts and stylesheets:


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


Here's a preview of what our angular application tree will look like. Since we installed the 'angular-templates' gem, we can keep all of our html files in the assets/javascript directory with all of our other angular files. 
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


First thing's first, let's declare our application in `app.js` and inject the necessary dependencies:
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
What we've just done is called our angular app, 'myApp', and called the config function, passing in $stateProvider and $routerUrlProvider as parameters. Immediately we can call $stateProvider and start chaining `.state()` methods, which take two parameters, the name of the state ('home' for example), and an object of data that describes the state, such as it's url, html template, and which controller to use. We're also using $urlRouterProvider just to make sure that the user can't navigate anywhere but to our predetermined states.


A few things you may not yet be familiar with up to this point are `onEnter`, `$state`, and `Auth`. We'll get to that later. 


Now let's build our `home.html` and `HomeCtrl.js`:
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


You may want to comment the login/register states and run `$ rails s` to make sure everything is working. If it is you'll see a big beautiful "Hello World". If it's right at the top towards the middle, take a deep breath of relief because Bootstrap is kicking in and that `col-lg` stuff is positioning it nicely rather than being stuck in the top left corner. 


What Angular has done is searched the DOM, found the attribute `ng-app`, initialized "myApp", navigated to `/home` by default from our router, located the `<ui-view>` directive, instantiated our `HomeCtrl`, injected the `$scope` object, added a key of `hello`, assigned it a value of `"Hello World"`, and then rendered `home.html` with this information within the `<ui-view>` element. Once in the view, Angular scans for any meaningful commands such as the `{{...}}` bindings and the `ng-if` directive and renders the controller's information as needed. I will admit the order of these operations may be off slightly but you get the jist of what’s going on under the hood.




Since we've got all of this nitty gritty behind the scenes information out of the way, let's build out our `AuthCtrl.js` and `login.html`/`register.html` files:


```
# login.js
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
# register.js
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


Before I overwhelm you with the AuthCtrl, I just want to point out that most of what you're seeing are Bootstraped CSS classes so that you're all super impressed with how beautifully this renders. Ignore all of the class attributes, and everything else should be pretty familiar, such as `ng-submit`, `ng-model`, and `ui-sref`, which takes the places of our usual `href` a-tag attribute. Now for the AuthCtrl... are you ready?


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


Most of this code is derived from the Angular Devise documentation (https://github.com/cloudspace/angular_devise), so I won't go into too much detail. What you need to know now is that `Auth` is thee service created by `angular-device` and it comes with some pretty awesome functions, such as `Auth.login(userParameters, config)` and `Auth.register(userParameters, config)`. These create a promise, which returns the logged in user once resolved. 


I will admit that I've cheated a bit here and assigned that user to the `$rootScope`, however a better performing, more scalable approach would be to create a UserService, store the user there, and then inject UserService into any of your controllers that need the user. For the sake of brevity, I also used a simple `alert()` function in lieu of integrating `ngMessages` or another service like `ngFlash` to make announcements about errors or successful login events.


The rest should be pretty self explanatory, the `ng-submit` forms are attached to these `$scope` functions, `$scope.user` is pulling the information from the `ng-model`s on the form inputs, and `$state.go()` is a nifty function for redirecting to another state.


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


All we're doing here is setting up the functions to use in the navigation links such as `ng-hide="signedIn()"` and `ng-click="logout()"` and adding listeners to the `$scope` so that we can trigger actions when certain `devise` specific events occur. We're also calling `Auth.currentuser()` so that when this controller is instantiated, we can double check our `$rootScope.user` object and display the proper nav links.


Let's find `app/views/application/index.html` again and add `<nav-bar></nav-bar>` on the line above `<ui-view>`. Since this isn't tied to any of the routes, it will always render above our main content.


Go ahead and refresh your page now. Don't you love it when things just work? Hopefully you don't have any weird issues with an out of date bundle, version of Ruby, or something funky like that. Just remember, Google is your best friend. 


Anywho, I hope this has helped! Please leave comments with questions, comments, or suggestions :)