require "test_helper"

class ActionJobTest < ActiveJob::TestCase
  class NoopActionJob < ActionJob
    private

    def process(activity, action, feedback) = nil
  end

  class WarningActionJob < ActionJob
    private

    def process(activity, action, feedback)
      feedback.add_to_warnings(subtype: :test_warning)
    end
  end

  class RaisingActionJob < ActionJob
    private

    def process(activity, action, feedback)
      feedback.add_to_warnings(subtype: :test_warning)
      raise "boom"
    end
  end

  class UnimplementedActionJob < ActionJob; end

  setup do
    @activity = create_activity(
      type: :create_or_update_records,
      config: {action: "create", auto_advance: false},
      files: create_uploaded_files(["test.csv"])
    )
    data_item = DataItem.create!(data: {foo: "bar"}, position: 101, activity: @activity)
    @action = Action.create!(task: @activity.current_task, data_item: data_item)
  end

  test "completes the action and stores nil feedback when there is nothing to report" do
    NoopActionJob.perform_now(@activity, @action)

    @action.reload
    assert @action.progress_completed?
    assert_not_nil @action.started_at
    assert_nil @action.feedback
  end

  test "stores feedback added by #process" do
    WarningActionJob.perform_now(@activity, @action)

    @action.reload
    assert @action.progress_completed?
    assert_equal [:test_warning], @action.feedback_for.warnings.map(&:subtype)
    assert @action.feedback_for.ok?
  end

  test "completes the action with an application_error when #process raises" do
    RaisingActionJob.perform_now(@activity, @action)

    @action.reload
    feedback = @action.feedback_for
    assert @action.progress_completed?
    assert_equal [:application_error], feedback.errors.map(&:subtype)
    assert_equal [:test_warning], feedback.warnings.map(&:subtype), "feedback gathered before the error is kept"
  end

  test "re-running a completed action leaves its feedback and the task counter unchanged" do
    task = @action.task
    task.update_columns(progress_status: Progressable::RUNNING, actions_count: 2, actions_completed_count: 0)

    WarningActionJob.perform_now(@activity, @action)
    completed_at = @action.reload.completed_at
    assert_equal 1, task.reload.actions_completed_count

    WarningActionJob.perform_now(@activity, @action)

    @action.reload
    assert @action.progress_completed?
    assert_equal completed_at, @action.completed_at
    assert_equal [:test_warning], @action.feedback_for.warnings.map(&:subtype)
    assert_equal 1, task.reload.actions_completed_count
  end

  test "a subclass without #process raises NotImplementedError" do
    assert_raises(NotImplementedError) do
      UnimplementedActionJob.perform_now(@activity, @action)
    end
  end
end
