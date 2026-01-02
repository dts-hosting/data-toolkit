class Current < ActiveSupport::CurrentAttributes
  attribute :collectionspace, :session
  delegate :user, to: :session, allow_nil: true
end
