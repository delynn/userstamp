module Ddb #:nodoc:
  module Userstamp
    mattr_accessor :compatibility_mode
    @@compatibility_mode = false
    
    module Stampable
      def self.included(base) # :nodoc:
        super
        
        base.extend(ClassMethods)
        base.class_eval do
          include InstanceMethods
          
          class_inheritable_accessor  :record_userstamp, :stamper_class_name, :creator_attribute,
                                      :updater_attribute, :deleter_attribute
          self.record_userstamp = true
          self.stampable
        end
      end

      module ClassMethods
        def stampable(options = {})
          defaults  = {
                        :stamper_class_name => :user,
                        :creator_attribute  => Ddb::Userstamp.compatibility_mode ? :created_by : :creator_id,
                        :updater_attribute  => Ddb::Userstamp.compatibility_mode ? :updated_by : :updater_id,
                        :deleter_attribute  => Ddb::Userstamp.compatibility_mode ? :deleted_by : :deleter_id
                      }.merge(options)

          self.stamper_class_name = defaults[:stamper_class_name].to_sym
          self.creator_attribute  = defaults[:creator_attribute].to_sym
          self.updater_attribute  = defaults[:updater_attribute].to_sym
          self.deleter_attribute  = defaults[:deleter_attribute].to_sym

          class_eval do
            belongs_to :creator, :class_name => self.stamper_class_name.to_s.singularize.camelize,
                                 :foreign_key => self.creator_attribute
                                 
            belongs_to :updater, :class_name => self.stamper_class_name.to_s.singularize.camelize,
                                 :foreign_key => self.updater_attribute
                                 
            before_save     :set_updater_attribute
            before_create   :set_creator_attribute
                                 
            if defined?(Caboose::Acts::Paranoid)
              belongs_to :deleter, :class_name => self.stamper_class_name,
                                   :foreign_key => self.deleter_attribute
              before_destroy  :set_deleter_attribute
            end
          end
        end
        
        def without_stamps
          original_value = self.record_userstamp
          self.record_userstamp = false
          yield
          self.record_userstamp = original_value
        end
        
        def stamper_class
          stamper_class_name.to_s.capitalize.constantize rescue nil
        end
      end

      module InstanceMethods
        private
          def has_stamper?
            !self.class.stamper_class.nil? && !self.class.stamper_class.stamper.nil?
          end

          def set_creator_attribute
            return unless self.record_userstamp
            if respond_to?(self.creator_attribute.to_sym) && has_stamper?
              write_attribute(self.creator_attribute, self.class.stamper_class.stamper)
            end
          end

          def set_updater_attribute
            return unless self.record_userstamp
            if respond_to?(self.updater_attribute.to_sym) && has_stamper?
              write_attribute(self.updater_attribute, self.class.stamper_class.stamper)
            end
          end

          def set_deleter_attribute
            return unless self.record_userstamp
            if respond_to?(self.deleter_attribute.to_sym) && has_stamper?
              write_attribute(self.deleter_attribute, self.class.stamper_class.stamper)
              save
            end
          end
        #end private
      end
    end
  end
end

ActiveRecord::Base.send(:include, Ddb::Userstamp::Stampable) if defined?(ActiveRecord)