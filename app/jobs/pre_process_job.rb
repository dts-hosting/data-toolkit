class PreProcessJob < ApplicationJob
  queue_as :default

  # This job spawns a sub-job for each data item
  def perform(task)
    task.start!
    Rails.logger.info "Pre process job started"

    # TODO: pre-checks b4 spawning sub jobs i.e required headers present etc.?
    # if failed
    #   # attach some kind of error report to the task
    #   task.fail! && return
    # end

    sleep 10 # tmp for testing
    task.data_items.in_batches(of: 1000) do |batch|
      jobs = batch.map { |data_item| PreProcessDataItemJob.new(data_item) }
      ActiveJob.perform_all_later(jobs)
    end

    Rails.logger.info "Pre process job finished spawning sub-jobs"
  end
end
