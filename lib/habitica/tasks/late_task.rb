# frozen_string_literal: true

require 'delegate'

module Habitica
  module Tasks
    class LateTask < SimpleDelegator
      include StorableTask

      def initialize(task)
        raise ArgumentError, 'task is not a HabiticaClient::Task instance' unless task.is_a?(HabiticaClient::Task)
        raise ArgumentError, 'task cannot be considered as a late task' unless self.class.match?(task)

        super
      end

      def self.match?(task)
        task.text =~ /^\[LATE\]/
      end

      def self.build_from(client, incompleted_recuring_task)
        result = client.tasks.create(
          text: "[LATE] #{incompleted_recuring_task.text}",
          notes: incompleted_recuring_task.notes,
          date: Date.today.to_s,
          type: 'todo',
          priority: 2
        )
        LateTask.new(result)
      end
    end
  end
end
