# Activities, Tasks & Jobs

```
Activity
  -> workflow: ordered list of task types
    -> Task
      -> handler job              (once per task)
      -> action_handler job       (once per data item, optional)
      -> finalizer job            (only if the task did not succeed, optional)
```

## Activity (`app/models/activity.rb`, `activity_type`)

A user request (e.g. "Check Media Derivatives"). `workflow` lists task types in run order.
On create, one Task is created per workflow entry; after commit `WorkflowManager.start_workflow` runs the first.

## Task (`app/models/task.rb`, `task_type`)

One workflow step. Config:

- `handler` (required): job enqueued when the task runs. `perform(task)`
- `action_handler` (optional): job run once per data item. `perform(activity, action)`
- `finalizer` (optional): runs after the task completes _without_ succeeding (aggregates feedback / builds report)
- `depends_on`: task types that must have succeeded first

When a task runs and has an `action_handler`, one Action is built per DataItem
(items that errored in an earlier task are skipped; zero actions -> task fails).

## Jobs: the contract

All state changes go through `WorkflowManager` (`app/services/workflow_manager.rb`); never set status columns directly.

**Handler-only task** (e.g. `ProcessUploadedFilesJob`)

1. `WorkflowManager.start_task(task)`
2. do the work
3. `WorkflowManager.complete_task(task, outcome: Task::SUCCEEDED | Task::FAILED, feedback:)`

**Task with actions**

- Handler: `GenericQueueActionJob` (`app/jobs/generic_queue_action_job.rb`). It starts the task and
  enqueues `task.action_handler` per action. For up-front checks, subclass it and override
  `ready?(task, feedback)`: add errors to `feedback` and return false to fail the task
  (e.g. `PreCheckIngestDataJob`).
  The task is NOT completed by the handler; it finalizes itself when the last action completes.
- Action handler: subclass `ActionJob` (`app/jobs/action_job.rb`) and implement
  `process(activity, action, feedback)`. Work on `action.data_item.data`
  (use `activity.data_handler` for CollectionSpace) and add errors/warnings to `feedback`.
  The base class starts and completes the action, and turns any exception into an
  `application_error`, so the action can never be left running. `feedback` starts empty on
  every run, and a job for an already-completed action does nothing.
- Task outcome is computed from the actions: all errored -> failed; any errors/warnings -> review; else succeeded.

**Rules**

- Handler-only jobs: always `rescue => e`, add `feedback.add_to_errors(subtype: :application_error, details: e)`,
  and complete the task. An uncompleted task stalls the activity until `TaskReconcilerJob` fails it (~15 min).
- Jobs may be retried or re-run: keep them idempotent.

## Recipe: new per-item step

1. Write the action job (+ test in `test/jobs/`):

   ```ruby
   class FooActionJob < ActionJob
     private

     def process(activity, action, feedback)
       data = action.data_item.data
       # ... do the work, then report problems:
       feedback.add_to_errors(subtype: :some_subtype, details: "...") unless ok
     end
   end
   ```

2. Register it in `app/models/task.rb`:

   ```ruby
   task_type :foo do
     display_name "Foo"
     handler GenericQueueActionJob # or a subclass with ready? checks
     action_handler FooActionJob
     finalizer GenericFeedbackReportJob # or GenericTaskFinalizerJob
     depends_on :process_uploaded_files
   end
   ```

3. Add `:foo` to the activity's `workflow` in `app/models/activity.rb`.
