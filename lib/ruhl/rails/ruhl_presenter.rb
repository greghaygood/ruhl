require 'ruhl/rails/active_record'
require 'ruhl/rails/helper'

module Ruhl
  module Rails
    class Presenter
      include Ruhl::Rails::ActiveRecord
      include Ruhl::Rails::Helper
  
      attr_reader :presentee, :context
  
      def initialize(context, obj = nil)
        @context = context

        # May only want to use the form helper
        if obj
          @presentee = obj
          define_paths(obj.class.name.underscore.downcase)
        end
      end
    
      def method_missing(name, *args)
        # Pass presenter method call to model so you don't have to
        # redefine every model method in the presenter class.
        presentee.__send__(name, *args)
      rescue NoMethodError 
        # Instead of saying context.link_to('Some site', some_path)
        # can just use link_to
        context.__send__(name, *args)
      end

      # Extend scope of respond_to? to model.
      def respond_to?(name)  
        if super
          true
        else
          presentee.respond_to?(name)
        end
      end  
    end
  end
end

module ActionController
  class Base    

    protected

    def present(options = {})
      controller_option = options.delete(:controller)

      action_sym      = options.delete(:action) || action_name
      object_sym      = options.delete(:object) || controller_option || controller_name.singularize
      controller_sym  = controller_option || controller_name

      options[:template] = "#{controller_sym}/#{action_sym}"
      options[:locals] = {:object => presenter_for(object_sym), :layout => options.delete(:layout) }

      render options 
    end

    def presenter_for(object)

      if object.is_a?(Symbol) || object.is_a?(String)
        # Set instance variable if it exists
        if instance_variables.include?("@#{object}")
          obj = instance_variable_get("@#{object}")
        end
        name = object.to_s.camelize
      else
        name = object.class.name.camelize
        obj = object
      end

      Object.const_get("#{name}Presenter").new(@template, obj)
    end

    helper_method :presenter_for   
  end
end
