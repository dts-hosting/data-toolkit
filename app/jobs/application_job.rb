class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::ConnectionNotEstablished,
    PG::ConnectionBad,
    wait: :polynomially_longer, attempts: 10

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  def log_finish
    Rails.logger.info "#{self.class.name} finished"
  end
end
