# frozen_string_literal: true

class FeedbackError < FeedbackElement
  GENERAL_CATEGORIES = ["application error"]

  MSGS = {
    "Tasks::PreCheckIngestData" => {
      "empty header" => {
        singular: "A data column in your CSV has a " \
          "blank/empty header. Either enter the correct field name for " \
          "the column, or delete the column.",
        plural: "Data columns in your CSV have blank/empty headers. " \
          "Either enter the correct field names for these columns, or " \
          "delete the columns lacking headers."
      },
      "required field missing" => {
        singular: "Your CSV is missing a required column",
        plural: "Your CSV is missing required columns"
      },
      "required field value(s) missing" => {
        aggregate: "One or more rows has empty required field(s). These " \
          "rows will not be ingested.",
        report_header: "ERR required value missing"
      }
    }
  }
end
