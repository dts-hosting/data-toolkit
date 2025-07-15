# Mixin module included in any application-specific error classes
#
# This allows each application-specific error to:
#
# - be subclassed to proper exception class in standard Ruby exception
#   hierarchy
# - be identified or rescued by standard Ruby exception
#   hierarchy ancestor, OR by application-specific error status
module DataToolkitError; end

class FeedbackSubtypeError < StandardError
  include DataToolkitError
end
