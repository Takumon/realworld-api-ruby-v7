module Support
  module Settable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def get(name)
        @settings = {} if @settings.nil?
        @settings[name]
      end

      def set(name, value)
        @settings = {} if @settings.nil?
        @settings[name] = value
      end
    end
  end
end
