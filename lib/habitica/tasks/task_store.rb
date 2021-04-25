require 'fileutils'

module Habitica
  module Tasks
    module StorableTask
      def custom_type
        raise NotImplementedError
      end
    end

    class TaskStore
      # @param location [String] a directory path to the store
      def initialize(location="#{ENV['HOME']}/.habitica_tasks/store")
        @location = location
        FileUtils.mkdir_p(@location)
      end

      # @param client [HabiticaClient::Client]
      # @return [Array<StorableTask>] an array of task like object
      def all_stored_tasks(client)
        Dir.glob(File.join(@location, '*.json')).map do |file|
          h = JSON.parse(File.read(file))
          case h['__task_type__']
          when 'future'
            FutureTask.parse(client, h)
          else
            raise "Unknown task_type: #{h['__task_type__']}"
          end
        end
      end

      # @param task [StorableTask]
      def store(task)
        task_file = File.join(@location, "#{task.id}.json")
        File.write(task_file, JSON.pretty_generate(task.to_h))
      end

      # @param task [StorableTask]
      def delete(task)
        task_file = File.join(@location, "#{task.id}.json")
        FileUtils.rm(task_file)
      end
    end
  end
end
