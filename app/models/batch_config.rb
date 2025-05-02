class BatchConfig < ApplicationRecord
  belongs_to :activity

  # TODO: attribute :authority_terms_duplicate_mode, :string, default: -> { BatchConfig.default_value(:authority_terms_duplicate_mode) }
  attribute :batch_mode, :string, default: -> { BatchConfig.default_value(:batch_mode) }
  attribute :check_record_status, :boolean, default: true
  attribute :date_format, :string, default: -> { BatchConfig.default_value(:date_format) }
  attribute :force_defaults, :boolean, default: false
  attribute :multiple_recs_found, :string, default: -> { BatchConfig.default_value(:multiple_recs_found) }
  attribute :null_value_string_handling, :string, default: -> { BatchConfig.default_value(:null_value_string_handling) }
  # TODO: attribute :record_matchpoint, :string, default: -> { BatchConfig.default_value(:record_matchpoint) }
  attribute :response_mode, :string, default: -> { BatchConfig.default_value(:response_mode) }
  attribute :search_if_not_cached, :boolean, default: true
  attribute :status_check_method, :string, default: -> { BatchConfig.default_value(:status_check_method) }
  attribute :strip_id_values, :boolean, default: true
  attribute :two_digit_year_handling, :string, default: -> { BatchConfig.default_value(:two_digit_year_handling) }

  # TODO: validates :authority_terms_duplicate_mode, inclusion: { in: -> { BatchConfig.values(:authority_terms_duplicate_mode) } }
  validates :batch_mode, inclusion: {in: -> { BatchConfig.values(:batch_mode) }}
  validates :check_record_status, inclusion: {in: [true, false]}
  validates :date_format, inclusion: {in: -> { BatchConfig.values(:date_format) }}
  validates :force_defaults, inclusion: {in: [true, false]}
  validates :multiple_recs_found, inclusion: {in: -> { BatchConfig.values(:multiple_recs_found) }}
  validates :null_value_string_handling, inclusion: {in: -> { BatchConfig.values(:null_value_string_handling) }}
  # TODO: validates :record_matchpoint, inclusion: { in: -> { BatchConfig.values(:record_matchpoint) } }
  validates :response_mode, inclusion: {in: -> { BatchConfig.values(:response_mode) }}
  validates :search_if_not_cached, inclusion: {in: [true, false]}
  validates :status_check_method, inclusion: {in: -> { BatchConfig.values(:status_check_method) }}
  validates :strip_id_values, inclusion: {in: [true, false]}
  validates :two_digit_year_handling, inclusion: {in: -> { BatchConfig.values(:two_digit_year_handling) }}

  def as_json(options = {})
    attrs = {
      batch_mode: batch_mode,
      check_record_status: check_record_status,
      date_format: date_format,
      force_defaults: force_defaults,
      multiple_recs_found: multiple_recs_found,
      null_value_string_handling: null_value_string_handling,
      response_mode: response_mode,
      search_if_not_cached: search_if_not_cached,
      status_check_method: status_check_method,
      strip_id_values: strip_id_values,
      two_digit_year_handling: two_digit_year_handling
    }

    options[:only] ? attrs.slice(*options[:only]) : attrs
  end

  # Supported attributes for user selection only
  def self.boolean_attributes
    [:strip_id_values]
  end

  def self.default_value(property)
    values(property).first
  end

  # Supported attributes for user selection only
  def self.select_attributes
    [
      :date_format,
      :multiple_recs_found,
      :null_value_string_handling,
      :two_digit_year_handling
    ]
  end

  # Used for validation and for select options in the ui
  def self.values(property)
    CollectionSpace::Mapper::BatchConfig::VALID_VALUES[property]
  end
end
