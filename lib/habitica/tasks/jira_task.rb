# frozen_string_literal: true

require 'delegate'

module Habitica
  module Tasks
    class JiraTask < SimpleDelegator
      include StorableTask

      attr_reader :ticket_id

      # @param task [HabiticaClient::Tasks]
      def initialize(task)
        raise ArgumentError, 'task is not a HabiticaClient::Task instance' unless task.is_a?(HabiticaClient::Task)
        raise ArgumentError, 'task cannot be considered as a jira task' unless self.class.match?(task)

        @ticket_id = self.class.extract_to_ticket_id(task)
        super
      end

      def self.match?(task)
        !!extract_to_ticket_id(task)
      end

      def self.extract_to_ticket_id(task)
        Regexp.last_match(1) if task.notes =~ PATTERN || task.text =~ PATTERN
      end

      PATTERN = /\[JIRA:(\w+-\d+)\]/.freeze

      def to_h
        h = super.to_h
        h['__task_type__'] = 'jira'
        h['__jira_ticket_id__'] = @ticket_id
        h
      end

      # @param client [HabiticaClient::Client]
      # @param hash [Hash] a hash representing a task
      # @return [Habitica::Tasks::JiraTask]
      def self.parse(client, hash)
        raise ArgumentError, 'hash does not describe a jira task' unless hash['__task_type__'] == 'jira'

        hash.delete('__task_type__')
        hash.delete('__jira_ticket_id__')

        Habitica::Tasks::JiraTask.new(HabiticaClient::Task.parse(client, hash))
      end

      def custom_type
        'jira'
      end
    end
  end
end
