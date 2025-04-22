require "test_helper"

class ProcessUploadedFilesJobTest < ActiveJob::TestCase
  # TODO Test that BatchImporter is called as expected

  test "job is performed successfully with valid CSVs" do
    assert_performed_jobs 0

    assert_nothing_raised do
      assert_performed_jobs 1, only: ProcessUploadedFilesJob do
        files = create_uploaded_files(["test.csv", "valid_lf.csv"])

        activity = create_activity({
          type: Activities::CheckMediaDerivatives,
          data_config: create_data_config_record_type(record_type: "media"),
          files: files
        })
        activity.save
      end
    end
  end

  test "job fails with invalid CSV" do
    assert_performed_jobs 0

    assert_nothing_raised do
      assert_performed_jobs 1, only: ProcessUploadedFilesJob do
        files = create_uploaded_files(["invalid_encoding.csv", "valid_lf.csv"])

        activity = create_activity({
          type: Activities::CheckMediaDerivatives,
          data_config: create_data_config_record_type(record_type: "media"),
          files: files
        })
        activity.save

        assert_equal "failed", activity.tasks.first.status
        assert_equal 1, activity.tasks.first.feedback["errors"].length
      end
    end
  end
end
