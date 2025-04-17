class PreCheckIngestDataJob < ApplicationJob
  queue_as :default

  # This job spawns a sub-job for each data item
  def perform(task)
    task.start!
    Rails.logger.info "Pre process job started"

    # TODO: pre-checks b4 spawning sub jobs i.e required headers present etc...
    # if failed
    #   # attach some kind of error report to the task
    #   task.fail!({errors: ["Not good!"]}) && return
    # end

    task.data_items.in_batches(of: 1000) do |batch|
      jobs = batch.map { |data_item| PreCheckIngestDataItemJob.new(data_item) }
      ActiveJob.perform_all_later(jobs)
    end

    Rails.logger.info "Pre process job finished spawning sub-jobs"
  rescue => e
    Rails.logger.error e.message
    task.fail!({errors: [e.message]})
  end
end
