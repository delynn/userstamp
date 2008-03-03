class UserstampController < ActionController::Base
  include Userstamp

  protected
    def current_user
      User.find(session[:user_id])
    end
  #end
end