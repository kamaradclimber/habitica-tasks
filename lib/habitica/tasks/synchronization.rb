module Habitica
  module Tasks
    class SynchronizationTask
      # @return [HabiticaClient::Client]
      attr_reader :client

      # @param client [HabiticaClient::Client]
      def initialize(client)
        @client = client
      end

      # synchronize
      def run
        raise NotImplementedError
      end

      # Takes a message and a block to display an action that can either succeed or fail
      # @param message [String]
      # @return [Object] the result of the block
      def log_action(message)
        print("#{message}...")
        res = yield
        puts 'DONE'
        res
      rescue RuntimeError
        puts 'FAILED'
        raise
      end

      # @param text [String] the text to summarize
      # @param max_size [Integer] the threshold to truncate. Defaults to 40
      # @return [String] the original string truncated if necessary
      def summarize(text, max_size: 40)
        if text.size >= max_size - 6
          "#{text[0..max_size - 6]}[...]"
        else
          text
        end
      end
    end

    class FutureTaskToStore < SynchronizationTask
      def task_store
        @task_store ||= Habitica::Tasks::TaskStore.new
      end

      def run
        client
          .tasks
          .filter_map { |task| Habitica::Tasks::FutureTask.new(task) if Habitica::Tasks::FutureTask.match?(task) }
          .each do |task|
          puts "Treating #{summarize(task.text)}:"
          puts "* should be created on #{task.to_create_date}"
          log_action('* storing in the store') do
            task_store.store(task)
          end
          log_action('* deleting from habitica') do
            res = task.delete
            raise 'Failed to delete the task' unless res
          end
        end
      end
    end

    class StoreToFutureTask < SynchronizationTask
      def task_store
        @task_store ||= Habitica::Tasks::TaskStore.new
      end
      def run
        task_store
          .all_stored_tasks(client)
          .select { |t| t.is_a?(Habitica::Tasks::FutureTask) }
          .each do |task|
          puts "Treating #{summarize(task.text)}:"
          puts "* task is due on #{task.to_create_date}"
          if task.to_create_date <= Date.today
            log_action('* storing to habitica') do
              task.recreate
            end
            log_action('* deleting from store') do
              task_store.delete(task)
            end
          else
            puts "* ignoring task because it's not relevant yet"
          end
        end
      end
    end
  end
end
