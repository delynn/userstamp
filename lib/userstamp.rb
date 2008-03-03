module Ddb
  module Controller
    module Userstamp
      def self.included(base) # :nodoc:
        base.before_filter  :set_stampers
        base.after_filter   :reset_stampers
        base.send           :include, InstanceMethods
      end

      module InstanceMethods
        private
          def set_stampers
            User.stamper = self.current_user
          end

          def reset_stampers
            User.reset_stamper
          end
        #end private
      end
    end
  end
end

ActionController::Base.send(:include, Ddb::Controller) if defined?(ActionController)