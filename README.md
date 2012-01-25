Userstamp Plugin (v 2.0)
========================

Overview
--------

The Userstamp Plugin extends [ActiveRecord::Base](http://api.rubyonrails.org/classes/ActiveRecord/Base.html) to add automatic updating of 'creator',
'updater', and 'deleter' attributes. It is based loosely on the [ActiveRecord::Timestamp](http://api.rubyonrails.org/classes/ActiveRecord/Timestamp.html) module.

Two class methods (`model_stamper` and `stampable`) are implemented in this plugin.
The `model_stamper` method is used in models that are responsible for creating, updating, or
deleting other objects. The `stampable` method is used in models that are subject to being
created, updated, or deleted by 'stampers'.


Installation
------------

Installation of the plugin can be done using the built in Rails plugin script. Issue the following
command from the root of your Rails application:

    $ ./script/rails plugin install git://github.com/delynn/userstamp.git

or add it to your Gemfile:

    gem 'userstamp'

and run `bundle install` to install the new dependency.

Once installed you will need to restart your application for the plugin to be loaded into the Rails
environment.

Usage
-----

In this new version of the Userstamp plug-in, the assumption is that you have two different
categories of objects; those that manipulate, and those that are manipulated. For those objects
that are being manipulated there's the Stampable module and for the manipulators there's the
Stamper module. There's also the actual Userstamp module for your controllers that assists in
setting up your environment on a per request basis.

To better understand how all this works, I think an example is in order. For this example we will
assume that a weblog application is comprised of User and Post objects. The first thing we need to
do is create the migrations for these objects, and the plug-in gives you a `userstamps`
method for very easily doing this:

```ruby
class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.timestamps
      t.userstamps
      t.name
    end
  end
  
  def self.down
    drop_table :users
  end
end

class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts, :force => true do |t|
      t.timestamps
      t.userstamps
      t.title
    end
  end
  
  def self.down
    drop_table :posts
  end
end
```

Second, since Users are going to manipulate other objects in our project, we'll use the
`model_stamper` method in our User class:

```ruby
class User < ActiveRecord::Base
  model_stamper
end
```

Finally, we need to setup a controller to set the current user of the application. It's
recommended that you do this in your ApplicationController:

```ruby
class ApplicationController < ActionController::Base
  include Userstamp
end
```

If all you are interested in is making sure all tables that have the proper columns are stamped
by the currently logged in user you can stop right here. More than likely you want all your
associations setup on your stamped objects, and that's where the `stampable` class method
comes in. So in our example we'll want to use this method in both our User and Post classes:

```ruby
class User < ActiveRecord::Base
  model_stamper
  stampable
end

class Post < ActiveRecord::Base
  stampable
end
```

Okay, so what all have we done? The `model_stamper` class method injects two methods into the
User class. They are #stamper= and #stamper and look like this:

```ruby
def stamper=(object)
  object_stamper = if object.is_a?(ActiveRecord::Base)
    object.send("#{object.class.primary_key}".to_sym)
  else
    object
  end
  
  Thread.current["#{self.to_s.downcase}_#{self.object_id}_stamper"] = object_stamper
end

def stamper
  Thread.current["#{self.to_s.downcase}_#{self.object_id}_stamper"]
end
```

The big change with this new version is that we are now using Thread.current to save the current
stamper so as to avoid conflict with concurrent requests.

The `stampable` method allows you to customize what columns will get stamped, and also
creates the _creator_, _updater_, and _deleter_ associations.

The Userstamp module that we included into our ApplicationController uses the setter method to
set which user is currently making the request. By default the 'set_stampers' method works perfectly
with the [RestfulAuthentication](http://svn.techno-weenie.net/projects/plugins/restful_authentication) plug-in:

```ruby
def set_stampers
  User.stamper = self.current_user
end
```

If you aren't using ActsAsAuthenticated, then you need to create your own version of the
`set_stampers` method in the controller where you've included the Userstamp module.

Now, let's get back to the Stampable module (since it really is the interesting one). The Stampable
module sets up before_* filters that are responsible for setting those attributes at the appropriate
times. It also creates the belongs_to relationships for you.

If you need to customize the columns that are stamped, the `stampable` method can be
completely customized. Here's an quick example:

```ruby
class Post < ActiveRecord::Base
  acts_as_stampable :stamper_class_name => :person,
                    :creator_attribute  => :create_user,
                    :updater_attribute  => :update_user,
                    :deleter_attribute  => :delete_user
end
```

If you are upgrading your application from the old version of Userstamp, there is a compatibility
mode to have the plug-in use the old "_by" columns by default. To enable this mode, add the
following line to the Rails.root/config/initializers/userstamp.rb file:

```ruby
Ddb::Userstamp.compatibility_mode = true
```

If you are having a difficult time getting the Userstamp plug-in to work, I recommend you checkout
the sample application that I created. You can find this application on [GitHub](http://github.com/delynn/userstamp_sample)

Uninstall
---------

Uninstalling the plugin can be done using the built in Rails plugin script. Issue the following
command from the root of your application:

    script/plugin remove userstamp


Documentation
-------------

RDoc has been run on the plugin directory and is available in the doc directory.


Running Unit Tests
------------------

There are extensive unit tests in the "test" directory of the plugin. These test can be run
individually by executing the following command from the userstamp directory:

    ruby test/compatibility_stamping_test.rb
    ruby test/stamping_test.rb
    ruby test/userstamp_controller_test.rb


Bugs & Feedback
---------------

Bug reports and feedback are welcome via [GitHub Issues](https://github.com/delynn/userstamp/issues). I also encouraged everyone to clone the git repository and make modifications--I'll be more than happy to merge any changes from other people's branches that would be beneficial to the whole project.


Credits and Special Thanks
--------------------------

The original idea for this plugin came from the Rails Wiki article entitled
"Extending ActiveRecord" on the Rails Wiki (no longer published).