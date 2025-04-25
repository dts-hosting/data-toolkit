require "test_helper"

class BatchConfigTest < ActiveSupport::TestCase
  def setup
    @activity = create_activity
    @batch_config = BatchConfig.new(activity: @activity)
  end

  test "should be valid with required attributes" do
    assert @batch_config.valid?
  end

  test "should belong to an activity" do
    assert_respond_to @batch_config, :activity
    @batch_config.activity = nil
    assert_not @batch_config.valid?
  end

  test "should have default values" do
    new_config = BatchConfig.new(activity: @activity)

    assert_equal BatchConfig.default_value(:batch_mode), new_config.batch_mode
    assert_equal true, new_config.check_record_status
    assert_equal BatchConfig.default_value(:date_format), new_config.date_format
    assert_equal false, new_config.force_defaults
    assert_equal BatchConfig.default_value(:multiple_recs_found), new_config.multiple_recs_found
    assert_equal BatchConfig.default_value(:null_value_string_handling), new_config.null_value_string_handling
    assert_equal BatchConfig.default_value(:response_mode), new_config.response_mode
    assert_equal true, new_config.search_if_not_cached
    assert_equal BatchConfig.default_value(:status_check_method), new_config.status_check_method
    assert_equal true, new_config.strip_id_values
    assert_equal BatchConfig.default_value(:two_digit_year_handling), new_config.two_digit_year_handling
  end

  test "string attributes should be included in valid values" do
    inclusion_validated_attributes = [
      :batch_mode, :date_format, :multiple_recs_found,
      :null_value_string_handling, :response_mode,
      :status_check_method, :two_digit_year_handling
    ]

    inclusion_validated_attributes.each do |attr|
      @batch_config[attr] = "invalid_value"
      assert_not @batch_config.valid?

      @batch_config[attr] = BatchConfig.values(attr).first
      @batch_config.valid?
    end
  end

  # TODO: make it a real example
  test "as_json should return all custom attributes" do
    batch_config = BatchConfig.new(
      activity: @activity,
      batch_mode: "vocabulary terms",
      check_record_status: true,
      date_format: "day month year",
      force_defaults: false,
      multiple_recs_found: "use_first",
      null_value_string_handling: "empty",
      response_mode: "verbose",
      search_if_not_cached: true,
      status_check_method: "cache",
      strip_id_values: true,
      two_digit_year_handling: "literal"
    )

    assert batch_config.valid?

    json_output = batch_config.as_json

    expected_keys = [
      :batch_mode, :check_record_status, :date_format, :force_defaults,
      :multiple_recs_found, :null_value_string_handling, :response_mode,
      :search_if_not_cached, :status_check_method, :strip_id_values,
      :two_digit_year_handling
    ]

    assert_equal expected_keys.sort, json_output.keys.sort

    assert_equal BatchConfig.values(:batch_mode).last, json_output[:batch_mode]
    assert_equal true, json_output[:check_record_status]
    assert_equal BatchConfig.values(:date_format).last, json_output[:date_format]
    assert_equal false, json_output[:force_defaults]
    assert_equal BatchConfig.values(:multiple_recs_found).last, json_output[:multiple_recs_found]
    assert_equal BatchConfig.values(:null_value_string_handling).last, json_output[:null_value_string_handling]
    assert_equal BatchConfig.values(:response_mode).last, json_output[:response_mode]
    assert_equal true, json_output[:search_if_not_cached]
    assert_equal BatchConfig.values(:status_check_method).last, json_output[:status_check_method]
    assert_equal true, json_output[:strip_id_values]
    assert_equal BatchConfig.values(:two_digit_year_handling).last, json_output[:two_digit_year_handling]
  end

  test "as_json with only option returns specified attributes" do
    json_output = @batch_config.as_json(only: [:check_record_status, :force_defaults])

    assert_equal [:check_record_status, :force_defaults].sort, json_output.keys.sort
    assert_equal true, json_output[:check_record_status]
    assert_equal false, json_output[:force_defaults]
  end
end
