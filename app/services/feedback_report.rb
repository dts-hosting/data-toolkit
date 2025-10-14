module FeedbackReport
  class Base
    attr_reader :actions, :file_path, :options
    def initialize(actions, file_path, **options)
      @actions = actions
      @file_path = file_path
      @options = options
    end
  end

  class CSV < Base
    def generate
      headers = %w[errors warnings]
      ::CSV.open(file_path, "w") do |csv|
        headers_written = false

        actions.find_each(batch_size: 500) do |action|
          action_feedback = action.feedback_for
          next unless action_feedback.displayable?

          data = action.data_item.data

          unless headers_written
            headers.unshift(*data.keys)
            csv << headers
            headers_written = true
          end

          # TODO: messages as well?
          data["errors"] = action_feedback.for_display.fetch(:errors, []).join(";")
          data["warnings"] = action_feedback.for_display.fetch(:warnings, []).join(";")
          csv_data = data.values_at(*headers)
          csv << csv_data
        end
      end
    end
  end
end
