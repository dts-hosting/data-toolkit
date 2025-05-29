# frozen_string_literal: true

class FeedbackMessage < FeedbackElement
  GENERAL_CATEGORIES = []

  MSGS = {
    "Tasks::PreCheckIngestData" => {
      "known fields" => {
        label: "Field(s) that will import"
      }
    }
  }
end
