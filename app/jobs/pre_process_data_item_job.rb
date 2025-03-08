class PreProcessDataItemJob < ApplicationJob
  queue_as :default

  def perform(data_item)
    data_item.update(status: "succeeded")
  end
end
