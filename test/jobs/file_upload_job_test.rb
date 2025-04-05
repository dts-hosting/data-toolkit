require "test_helper"

class FileUploadJobTest < ActiveJob::TestCase
  # TODO Test that BatchImporter is called as expected

  test "job is performed successfully with valid CSVs" do
    assert_performed_jobs 0

    assert_nothing_raised do
      assert_performed_jobs 1, only: FileUploadJob do
        files = create_uploaded_files(["test.csv", "valid_lf.csv"])

        activity = create_activity({
          type: Activities::AnalyzeMediaActivity,
          files: files
        })
        activity.save
      end
    end
  end

  test "job fails with invalid CSV" do
    assert_performed_jobs 0

    assert_nothing_raised do
      assert_performed_jobs 1, only: FileUploadJob do
        files = create_uploaded_files(["invalid_encoding.csv", "valid_lf.csv"])

        activity = create_activity({
          type: Activities::AnalyzeMediaActivity,
          files: files
        })
        activity.save

        assert_equal "failed", activity.tasks.first.status
        assert_equal 1, activity.tasks.first.feedback["errors"].length
      end
    end
  end
end
