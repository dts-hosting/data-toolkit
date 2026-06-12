class Task < ApplicationRecord
  include ActionView::RecordIdentifier
  include Feedbackable
  include Progressable
  include TaskDefinition

  SUCCEEDED = "succeeded"
  FAILED = "failed"
  REVIEW = "review"

  # Disable STI - we use "type" column for task type identifiers
  self.inheritance_column = :_type_disabled

  belongs_to :activity, touch: true
  delegate :user, to: :activity
  has_many :actions, dependent: :destroy
  has_many :data_items, through: :actions
  has_many_attached :files

  enum :outcome_status, {
    review: REVIEW,
    failed: FAILED,
    succeeded: SUCCEEDED
  }, prefix: :outcome

  broadcasts_refreshes

  def feedback_context
    "Tasks::#{type.to_s.camelize}"
  end

  def has_feedback?
    progress_completed? && !outcome_succeeded? &&
      (feedback_for.displayable? || actions.where.not(feedback: nil).any?)
  end

  def ok_to_run?
    met_dependencies? && progress_pending? && started_at.nil?
  end

  def checkin_frequency
    item_count = activity.data_items_count
    return 0 if item_count.zero?

    # cap 10% checkin, but lower as item count increases
    [Math.sqrt(item_count) / item_count, 0.1].min
  end

  def progress
    case progress_status
    when Progressable::PENDING, Progressable::QUEUED then 0
    when Progressable::RUNNING then calculate_progress
    when Progressable::COMPLETED then 100
    else 0
    end
  end

  def status
    progress_completed? ? outcome_status : progress_status
  end

  task_type :process_uploaded_files do
    display_name "Process Uploaded Files"
    handler ProcessUploadedFilesJob
  end

  task_type :pre_check_ingest_data do
    display_name "Pre-Check Ingest Data"
    handler PreCheckIngestDataJob
    action_handler PreCheckIngestActionJob
    finalizer GenericTaskFinalizerJob
    depends_on :process_uploaded_files
  end

  task_type :process_media_derivatives do
    display_name "Process Media Derivatives"
    handler GenericQueueActionJob
    action_handler ProcessMediaDerivativesActionJob
    finalizer GenericFeedbackReportJob
    depends_on :process_uploaded_files, :pre_check_ingest_data
  end

  private

  def calculate_progress
    return 0 if actions_count.zero?

    ((actions_completed_count.to_f / actions_count) * 100).round
  end

  def met_dependencies?
    return true if dependencies.empty?

    activity.tasks
      .where(type: dependencies.map(&:to_s), outcome_status: SUCCEEDED)
      .count == dependencies.size
  end
end
