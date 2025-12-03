class Task < ApplicationRecord
  include ActionView::RecordIdentifier
  include Feedbackable
  include Runnable
  include TaskDefinition

  # Disable STI - we use 'type' column for task type identifiers
  self.inheritance_column = :_type_disabled

  belongs_to :activity, touch: true
  delegate :user, to: :activity
  has_many :actions, dependent: :destroy
  has_many :data_items, through: :actions
  has_many_attached :files

  broadcasts_refreshes

  task_type :process_uploaded_files do
    display_name "Process Uploaded Files"
    handler ProcessUploadedFilesJob
    auto_trigger true
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

  def has_feedback?
    progress_completed? &&
      (feedback_for.displayable? || actions.where.not(feedback: nil).any?)
  end

  def feedback_context
    "Tasks::#{type.to_s.camelize}"
  end
end
