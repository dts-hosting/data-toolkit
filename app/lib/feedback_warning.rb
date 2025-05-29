# frozen_string_literal: true

class FeedbackWarning < FeedbackElement
  GENERAL_CATEGORIES = []

  MSGS = {
    "Tasks::PreCheckIngestData" => {
      "unknown fields" => {
        label: "Field(s) that will <b>not</b> import"
      }
    }
  }
end
