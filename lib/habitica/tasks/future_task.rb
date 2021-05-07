require 'delegate'

module Habitica
  module Tasks
    # A task that should be created only in the future
    class FutureTask < SimpleDelegator
      include StorableTask

      attr_reader :to_create_date

      # @param task [HabiticaClient::Tasks]
      def initialize(task)
        raise ArgumentError, "task is not a HabiticaClient::Task instance" unless task.is_a?(HabiticaClient::Task)
        raise ArgumentError, "task cannot be considered as a future task" unless self.class.match?(task)

        @to_create_date = self.class.extract_to_create_date(task)
        super
      end

      # @return [Boolean] true if task looks like a "future" task
      def self.match?(task)
        !!extract_to_create_date(task)
      end

      def self.extract_to_create_date(task)
        Date.parse($1) if task.notes =~ PATTERN
      end

      PATTERN = /\[create_on:(\d{4}-\d{2}-\d{2})\]/.freeze

      def to_h
        h = super.to_h
        h['__task_type__'] = 'future'
        h['__future_to_create_on__'] = @to_create_date.to_s
        h
      end

      # @param client [HabiticaClient::Client]
      # @param hash [Hash] a hash representing a task
      # @return [Habitica::Tasks::FutureTask]
      def self.parse(client, hash)
        raise ArgumentError, 'hash does not describe a future task' unless hash['__task_type__'] == 'future'

        hash.delete('__task_type__')
        hash.delete('__future_to_create_on__')

        Habitica::Tasks::FutureTask.new(HabiticaClient::Task.parse(client, hash))
      end

      def custom_type
        'future'
      end

      # Recreate the task from scratch in habitica. Will not be able to keep the origin task id
      def recreate
        id = self.id
        self.id = nil # force recreation
        hash = to_h
        checklist = hash.delete('checklist')
        challenge = hash.delete('challenge') # TODO: readd to challenge if necessary
        group = hash.delete('group') # TODO: readd to group if necessary
        %w[created_at updated_at by_habitica user_id __task_type__ __future_to_create_on__ value completed].each { |useless_field| hash.delete(useless_field) }

        url = __getobj__.send(:url).gsub(%r{/$}, '') # HACK: fix url to create new tasks

        response = client.client.class.post(url, body: hash.to_json)
        raise response.to_s unless response.success?

        raise "Now we should implement the ability to restore checklist" unless checklist.empty?
        raise "Now we should implement the ability to restore challenge" unless challenge.empty?
        # raise "Now we should implement the ability to restore group" unless group TODO
      ensure
        # we have to restore the id to be able to identify the task
        self.id = id
      end
    end

  end
end

