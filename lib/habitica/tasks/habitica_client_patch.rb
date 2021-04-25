require 'habitica_client'

# patch habitica_client to support new fields
class HabiticaClient
  class Task < HabiticaClient::Restful
    NEW_FIELDS = %i[
      counter_up counter_down by_habitica next_due yester_daily
      days_of_month weeks_of_month is_due
    ].freeze
    NEW_FIELDS.each do |field|
      attr_accessor field
    end

    Task.instance_methods.group_by { |m| m.to_s.gsub(/=$/, '') }.select { |k, v| k =~ /\w/ && v.size > 1 }.keys.then do |all_attr|
      hashup(*all_attr)
    end
  end

  class Client
    base_uri 'https://habitica.com/api/v3/'
    debug_output $stdout if ENV['TROUBLESHOOT_HTTP']
  end
end
