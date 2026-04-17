require "aws-sdk-cloudwatch"

module CloudWatch
  module_function

  def client
    @client ||= Aws::CloudWatch::Client.new
  end

  def env = Rails.configuration.cloudwatch_environment
  def namespace = Rails.configuration.cloudwatch_namespace

  def enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("CW_ENABLED", false))
  end
end
