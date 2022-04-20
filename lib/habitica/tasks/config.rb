# frozen_string_literal: true

require 'yaml'

module Habitica
  module Tasks
    class Config
      attr_reader :user_id, :api_token, :jira

      # @param hash [Hash] the hash describing the config
      def initialize(hash)
        @user_id = hash['user_id']
        @api_token = hash['api_token']

        @jira = hash['jira']
        @jira.transform_values! do |value|
          case value
          when /^\$(.+)/
            ENV[Regexp.last_match(1)] || (raise "Impossible to find #{value} in environment")
          else
            value
          end
        end
      end

      def self.load(file)
        file ||= "#{ENV['HOME']}/.config/habitica-tasks/config.yml"
        raise ArgumentError, "#{file} does not exist" unless File.exist?(file)

        config_yaml = YAML.safe_load(File.read(file))
        Config.new(config_yaml)
      end
    end
  end
end
