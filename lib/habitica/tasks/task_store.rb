# frozen_string_literal: true

require 'fileutils'
require 'habitica/tasks/tags'

module Habitica
  module Tasks
    module StorableTask
      def custom_type
        raise NotImplementedError
      end
    end

    # this store puts tasks "hidden" in habitica to avoid rely on a disk storage
    class HabiticaEmbeddedTaskStore
      # @param client [HabiticaClient::Client]
      def initialize(client)
        @client = client
        @tags_by_id = client.tags.map { |t| [t.id, t.name] }.to_h
      end

      def all_stored_tasks
        @client.tasks.dailies.select do |task|
          task_has_tag?(task, 'habitica-tasks-internal')
        end.map do |task|
          raise "Unknown task_type for #{task}" unless task_has_tag?(task, 'task-type:future')

          task.type = 'todo'
          t = FutureTask.new(task)
          # clean some fields (it might not be necessary after all)
          t.every_x = nil
          t.frequency = nil
          t.next_due = nil
          t
        end
      end

      def task_has_tag?(task, tag_name)
        task.tags.map { |tag_id| @tags_by_id[tag_id] }.include?(tag_name)
      end

      # @param task [StorableTask]
      def delete(task)
        task.delete
      end

      # @param task [StorableTask]
      def store(task)
        new_task = task.dup
        new_task.notes += "[due_on:#{new_task.date.strftime('%Y-%m-%d')}]" if new_task.date
        new_task.id = nil if new_task.type != 'daily' # let's create a new task if we are changing the task type
        new_task.type = 'daily'
        # in case this script does not run, the task will appear everyday
        new_task.every_x = 1
        new_task.frequency = 'daily'
        new_task.start_date = new_task.to_create_date.to_datetime.to_s
        new_task.tags << @tags_by_id.key('habitica-tasks-internal')
        new_task.tags << @tags_by_id.key('task-type:future')
        new_task.save
      end
    end

    class TaskStore
      # @param client [HabiticaClient::Client]
      # @param location [String] a directory path to the store
      def initialize(client, location = "#{ENV['HOME']}/.habitica_tasks/store")
        @client = client
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
