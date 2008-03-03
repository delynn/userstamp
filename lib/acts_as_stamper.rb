module Ddb #:nodoc:
  module Userstamp
    module ActsAsStamper
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_stamper
          # don't allow multiple calls
          return if self.included_modules.include?(Ddb::Userstamp::ActsAsStamper::StamperMethods)
          send(:extend, Ddb::Userstamp::ActsAsStamper::StamperMethods)
        end
      end

      module StamperMethods
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

        def reset_stamper
          Thread.current["#{self.to_s.downcase}_#{self.object_id}_stamper"] = nil
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, Ddb::Userstamp::ActsAsStamper) if defined?(ActiveRecord)