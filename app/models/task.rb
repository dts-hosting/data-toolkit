class Task < ApplicationRecord
  include ActionView::RecordIdentifier
  include Feedbackable
  include Runnable

  # Disable STI - we use "type" column for task type identifiers
  self.inheritance_column = :_type_disabled

  belongs_to :activity, touch: true
  delegate :user, to: :activity
  has_many :actions, dependent: :destroy
  has_many :data_items, through: :actions
  has_many_attached :files

  broadcasts_refreshes

  def feedback_context
    "Tasks::#{type.to_s.camelize}"
  end

  def has_feedback?
    progress_completed? &&
      (feedback_for.displayable? || actions.where.not(feedback: nil).any?)
  end

  task_type :process_uploaded_files do |t|
    t.display_name = "Process Uploaded Files"
    t.handler = ProcessUploadedFilesJob
    t.auto_trigger = true
  end

  task_type :pre_check_ingest_data do |t|
    t.display_name = "Pre-Check Ingest Data"
    t.handler = PreCheckIngestDataJob
    t.action_handler = PreCheckIngestActionJob
    t.finalizer = GenericTaskFinalizerJob
    t.depends_on :process_uploaded_files
  end

  task_type :process_media_derivatives do |t|
    t.display_name = "Process Media Derivatives"
    t.handler = GenericQueueActionJob
    t.action_handler = ProcessMediaDerivativesActionJob
    t.finalizer = GenericFeedbackReportJob
    t.depends_on :process_uploaded_files, :pre_check_ingest_data
  end
end
