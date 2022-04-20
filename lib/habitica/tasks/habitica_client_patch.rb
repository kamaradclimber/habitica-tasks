require 'habitica_client'

module Hashup
  # this patch makes sure we call the api with camelCased field instead of snake case
  def hashup(*attributes)
    define_method(:to_h) do
      kv = attributes.map do |k|
        old_k = k
        k = k.gsub(Regexp.last_match(0),
                   "#{Regexp.last_match(1)}#{Regexp.last_match(2).upcase}") while k =~ /([a-z])_([a-z])/
        [k, send(old_k)]
      end.delete_if { |_, v| v.nil? }
      Hash[kv]
    end
  end
end

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

    Task.instance_methods.group_by do |m|
      m.to_s.gsub(/=$/, '')
    end.select { |k, v| k =~ /\w/ && v.size > 1 }.keys.then do |all_attr|
      hashup(*all_attr)
    end

    # depending on the type of task will either complete the task (Todo/Dailies) or increase the score of a habbit
    def score_up
      uri = [url, 'score/up'].join('/')
      response = client.class.post(uri)
      raise ServerError, response['err'] unless response.response.code =~ /2\d{2}/

      response.parsed_response['data']
    end
  end

  class Client
    base_uri 'https://habitica.com/api/v3/'
    debug_output $stdout if ENV['TROUBLESHOOT_HTTP']
  end
end
