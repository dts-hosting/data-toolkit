class PreProcessDataItemJob < ApplicationJob
  queue_as :default

  def perform(data_item)
    data_item.start!
    # TODO: do some work lazy ...
    sleep 10 # real slow one ...
    data_item.success!
  rescue => e
    Rails.logger.error e.message
    data_item.fail!({errors: [e.message]})
  end
end
