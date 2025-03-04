module OptList
  module AllowOverride
    extend ActiveSupport::Concern
    included do
      def optlist_overrides
        true
      end
    end
  end

  module NoOverride
    extend ActiveSupport::Concern
    included do
      def optlist_overrides
        false
      end
    end
  end
end
