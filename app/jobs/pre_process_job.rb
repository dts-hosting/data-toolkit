class PreProcessJob < ApplicationJob
  queue_as :default

  # This job preprocesses data items and spawns a sub-job for each data item
  def perform(task)
    task.update(status: "running", started_at: Time.current)
    Rails.logger.info "Pre process job started"

    sleep 10
    task.data_items.each do |data_item|
      # TODO: PreProcessDataItemJob(data_item)
      data_item.update(status: "succeeded") # this would happen inside the job
    end

    Rails.logger.info "Pre process job finished spawning sub-jobs"
  end
end
