require "test_helper"

class FeedbackReportTest < ActiveSupport::TestCase
  setup do
    @activity = create_activity(
      type: "Activities::CheckMediaDerivatives",
      user: users(:admin),
      data_config: create_data_config_record_type(record_type: "media"),
      files: create_uploaded_files(["media.csv"])
    )
    @file_path = Rails.root.join("tmp", "test_report_#{SecureRandom.hex(8)}.csv")
  end

  teardown do
    File.delete(@file_path) if @file_path && File.exist?(@file_path)
  end

  test "generates CSV with headers and feedback data" do
    task = @activity.tasks.where(type: "process_media_derivatives").first
    actions = create_actions_with_feedback(task)

    report = FeedbackReport::CSV.new(actions, @file_path)
    report.generate

    assert File.exist?(@file_path), "CSV file should be created"

    csv_content = CSV.read(@file_path, headers: true)
    assert_equal 2, csv_content.length, "Should have 2 data rows"
    assert_includes csv_content.headers, "errors"
    assert_includes csv_content.headers, "warnings"
    assert_match(/error/, csv_content[0]["errors"])
  end

  test "handles empty actions gracefully" do
    actions = Action.none

    report = FeedbackReport::CSV.new(actions, @file_path)
    report.generate

    assert File.exist?(@file_path), "CSV file should be created even if empty"
    csv_content = CSV.read(@file_path)
    assert_equal 0, csv_content.length, "Should have no rows"
  end

  test "skips actions without displayable feedback" do
    task = @activity.tasks.where(type: "process_media_derivatives").first
    action_with_feedback = create_action_with_feedback(task)
    action_without_feedback = create_action_without_feedback(task)

    actions = Action.where(id: [action_with_feedback.id, action_without_feedback.id])

    report = FeedbackReport::CSV.new(actions, @file_path)
    report.generate

    csv_content = CSV.read(@file_path, headers: true)
    assert_equal 1, csv_content.length, "Should only include action with displayable feedback"
  end

  test "handles file write errors" do
    task = @activity.tasks.where(type: "process_media_derivatives").first
    actions = create_actions_with_feedback(task)
    invalid_path = "/invalid/path/report.csv"

    report = FeedbackReport::CSV.new(actions, invalid_path)

    assert_raises(Errno::ENOENT) do
      report.generate
    end
  end
end
