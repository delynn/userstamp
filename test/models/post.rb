class Post < ActiveRecord::Base
  acts_as_stampable :stamper_class_name => :person
  has_many :comments
end