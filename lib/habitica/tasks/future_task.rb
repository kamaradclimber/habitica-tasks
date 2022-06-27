# frozen_string_literal: true

require 'delegate'

module Habitica
  module Tasks
    # A task that should be created only in the future
    class FutureTask < SimpleDelegator
      include StorableTask

      # @return [DateTime]
      attr_reader :to_create_date

      # @param task [HabiticaClient::Task]
      def initialize(task)
        raise ArgumentError, 'task is not a HabiticaClient::Task instance' unless task.is_a?(HabiticaClient::Task)
        raise ArgumentError, 'task cannot be considered as a future task' unless self.class.match?(task)

        @to_create_date = self.class.extract_to_create_date(task)
        super
      end

      # @return [Boolean] true if task looks like a "future" task
      def self.match?(task)
        !!extract_to_create_date(task) && task.type == 'todo'
      end

      # @return [DateTime]
      def self.extract_to_create_date(task)
        Date.parse(Regexp.last_match(1)) if task.notes =~ PATTERN
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
        if notes =~ /\[due_on:(\d{4}-\d{2}-\d{2})\]/
          # recreating due date
          self.date = DateTime.parse(Regexp.last_match(1)).to_s
          notes.gsub!(Regexp.last_match(0), '')
        else
          self.date = to_create_date.to_s
        end
        # no update of the task beyond this point
        hash = to_h
        checklist = hash.delete('checklist')
        challenge = hash.delete('challenge') # TODO: readd to challenge if necessary
        group = hash.delete('group') # TODO: readd to group if necessary
        %w[created_at updated_at by_habitica user_id __task_type__ __future_to_create_on__ value
           completed].each do |useless_field|
          hash.delete(useless_field)
        end

        url = __getobj__.send(:url).gsub(%r{/$}, '') # HACK: fix url to create new tasks

        response = client.class.post(url, body: hash.to_json)
        raise response.to_s unless response.success?

        new_id = response['data']['id']
        restore_checklist(new_id, checklist)

        raise 'Now we should implement the ability to restore challenge' unless challenge.empty?
        raise 'Now we should implement the ability to restore group' unless group
      ensure
        # we have to restore the id to be able to identify the task
        self.id = id
      end

      def restore_checklist(id, checklist)
        url = __getobj__.send(:url).gsub('/user', '') + "#{id}/checklist"
        checklist.each do |item|
          response = client.class.post(url, body: { text: item['text'] }.to_json)
          raise response.to_s unless response.success?

          next unless item['completed']

          item_id = response['data']['checklist'].last['id']
          response = client.class.post(url + "/#{item_id}/score")
          raise response.to_s unless response.success?
        end
      end
    end
  end
end
