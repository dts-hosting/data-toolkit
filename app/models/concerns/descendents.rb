module Descendents
  extend ActiveSupport::Concern

  module ClassMethods
    def descendants_by_display_name
      Rails.application.eager_load! if Rails.env.development?
      descendants = ObjectSpace.each_object(Class).select { |klass| klass < self }

      descendants.map do |klass|
        [klass.display_name, klass.to_s]
      end.to_h
    end

    def display_names
      descendants_by_display_name.keys.sort
    end
  end
end
