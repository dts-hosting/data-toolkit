module Descendents
  extend ActiveSupport::Concern

  module ClassMethods
    def descendants_by_display_name
      Rails.application.eager_load!
      descendants = ObjectSpace.each_object(Class).select { |klass| klass < self }

      descendants.map do |klass|
        [klass.display_name, klass]
      end.to_h
    end

    def display_names
      descendants_by_display_name.keys.sort
    end

    def find_type_by_param_name(param_name)
      type = descendants_by_display_name.find do |name, _|
        name.parameterize == param_name
      end
      type&.last
    end
  end
end
