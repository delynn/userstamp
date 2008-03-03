module Ddb #:nodoc:
  module Userstamp
    module ActsAsStampable
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_stampable(options = {})
          # don't allow multiple calls
          return if self.included_modules.include?(Ddb::Userstamp::ActsAsStampable::InstanceMethods)
          send(:include, Ddb::Userstamp::ActsAsStampable::InstanceMethods)
          
          defaults  = {
                        :record_stamps      => true,
                        :stamper_class_name => :user,
                        :creator_attribute  => 'creator_id',
                        :updater_attribute  => 'updater_id',
                        :deleter_attribute  => 'deleter_id'
                      }.merge(options)

          class_inheritable_accessor  :record_stamps,
                                      :stamper_class_name,
                                      :creator_attribute,
                                      :updater_attribute,
                                      :deleter_attribute
                                      
          

          self.record_stamps      = defaults[:record_stamps]
          self.stamper_class_name = defaults[:stamper_class_name].to_s.singularize.camelize
          self.creator_attribute  = defaults[:creator_attribute].to_s
          self.updater_attribute  = defaults[:updater_attribute].to_s
          self.deleter_attribute  = defaults[:deleter_attribute].to_s

          class_eval do
            belongs_to :creator, :class_name => self.stamper_class_name,
                                 :foreign_key => self.creator_attribute
                                 
            belongs_to :updater, :class_name => self.stamper_class_name,
                                 :foreign_key => self.updater_attribute

            before_save     :set_updater_attribute
            before_create   :set_creator_attribute

            if defined?(ActsAsParanoid)
              belongs_to :deleter, :class_name => self.stamper_class_name,
                                   :foreign_key => self.deleter_attribute
              before_destroy :set_deleter_attribute
            end
          end
        end
        
        def without_stamps
          current_record_stamps_value = self.record_stamps
          self.record_stamps = false
          yield
          self.record_stamps = current_record_stamps_value
        end
      end

      module InstanceMethods
        private
          def set_creator_attribute
            return unless self.record_stamps
            if respond_to?(self.creator_attribute.to_sym) && !self.stamper_class_name.constantize.stamper.nil?
              write_attribute(self.creator_attribute, self.stamper_class_name.constantize.stamper)
            end
          end

          def set_updater_attribute
            return unless self.record_stamps
            if respond_to?(self.updater_attribute.to_sym) && !self.stamper_class_name.constantize.stamper.nil?              
              write_attribute(self.updater_attribute, self.stamper_class_name.constantize.stamper)
            end
          end

          def set_deleter_attribute
            return unless self.record_stamps
            if respond_to?(self.deleter_attribute.to_sym) && !self.stamper_class_name.constantize.stamper.nil?
              write_attribute(self.deleter_attribute, self.stamper_class_name.constantize.stamper)
              save
            end
          end
        #end private
      end
    end
  end
end

ActiveRecord::Base.send(:include, Ddb::Userstamp::ActsAsStampable) if defined?(ActiveRecord)