class BatchImporter
  def initialize(task, batch_size: 1000)
    @task = task
    @batch_size = batch_size
    @data_items = []
    @current_position = 0
  end

  def process_row(row)
    @data_items << {
      activity_id: @task.activity_id,
      current_task_id: @task.id,
      position: @current_position,
      data: row,
      created_at: Time.current,
      updated_at: Time.current
    }

    @current_position += 1

    flush_batch if batch_full?
  end

  def finalize
    flush_batch if @data_items.any?
  end

  private

  def batch_full?
    @data_items.size >= @batch_size
  end

  def flush_batch
    ActiveRecord::Base.transaction do
      DataItem.insert_all(@data_items)
    end

    @data_items = []
  end
end
