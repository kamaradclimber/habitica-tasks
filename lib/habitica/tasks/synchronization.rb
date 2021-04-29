require 'habitica/tasks/future_task'
require 'habitica/tasks/jira_task'

module Habitica
  module Tasks
    class SynchronizationTask
      # @return [HabiticaClient::Client]
      attr_reader :client

      # @return [Habitica::Tasks::TaskStore]
      attr_reader :task_store

      # @return [Habitica::Tasks::Config]
      attr_reader :config

      # @param client [HabiticaClient::Client]
      def initialize(client, config)
        @client = client
        @config = config
        @task_store = Habitica::Tasks::TaskStore.new
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

    class JiraToHabitica < SynchronizationTask
      def resolved_label
        'habitica:achieved'
      end

      def run
        # TODO(g.seux): allow to configure search query
        unresolved_tickets = jira_client.Issue.jql("assignee = currentUser()  AND resolution is EMPTY AND issuetype not in (Epic) AND updated > -60days")
        # TODO(g.seux): allow to store "achieved" tickets locally instead of updating tickets with a label
        achieved = jira_client.Issue.jql("assignee = currentUser()  AND resolution is not EMPTY AND issuetype not in (Epic) AND updated > -60days AND (labels is EMPTY or labels not in (#{resolved_label}))")
        jira_tasks = client
          .tasks
          .filter_map { |task| Habitica::Tasks::JiraTask.new(task) if Habitica::Tasks::JiraTask.match?(task) }

        created_tasks = create_missing_tickets(unresolved_tickets + achieved, jira_tasks)
        resolve_tasks(achieved, jira_tasks + created_tasks)
      end

      # @param tickets [Array<JIRA::Resource::Issue>] issue in jira
      # @param jira_tasks [Array<Habitica::Tasks::JiraTask>] tasks already existing in habitica
      # Will resolve tasks in habitica for issues that have been resolved in jira
      def resolve_tasks(tickets, jira_tasks)
        tasks_by_ticket_id = jira_tasks.map { |t| [t.ticket_id, t] }.to_h
        tickets.each do |ticket|
          raise "Impossible to find task matching #{ticket.key}" unless tasks_by_ticket_id.key?(ticket.key)

          log_action("Complete #{ticket.key}") do
            existing_labels = ticket.fields['labels']
            result = ticket.save({fields: { labels: existing_labels + [resolved_label]}})
            raise "Failure to update ticket" unless result

            tasks_by_ticket_id[ticket.key].score_up
          end
        end
      end

      # @param tickets [Array<JIRA::Resource::Issue>] issue in jira
      # @param jira_tasks [Array<Habitica::Tasks::JiraTask>] tasks already existing in habitica
      # Will create tasks in habitica for issues that have no corresponding task
      # @return [Array<Habitica::Tasks::JiraTask>] all tasks created
      def create_missing_tickets(tickets, jira_tasks)
        tickets
          .reject { |task| jira_tasks.map(&:ticket_id).include?(task.key) } # this is not optimal but good enough
          .map { |issue| create(issue) }
      end

      # @param issue [JIRA::Resource::Issue]
      # Create a task in habitica based on the passed issue
      def create(issue)
        log_action("Creating #{issue.key} in habitica") do
          result = client.tasks.create(
            text: issue.summary,
            notes: "[JIRA:#{issue.key}]",
            type: 'todo',
            # TODO(g.seux): allow to deal with tickets without story points
            priority: _story_point_to_priority(issue.fields['customfield_10004'])
          )
          Habitica::Tasks::JiraTask.new(result)
        end
      end

      def jira_client
        require 'jira-ruby'
        options = {
          username: config.jira['username'],
          password: config.jira['password'],
          site: config.jira['site'],
          context_path: config.jira['context_path'] || '',
          auth_type: config.jira['auth_type']&.to_sym || :basic
        }
        @jira_client ||= JIRA::Client.new(options)
      end

      # @param story_points [Integer]
      # @return [Float] the priority (0.1, 1, 1.5, 2)
      def _story_point_to_priority(story_points)
        # this assumes tasks are sized with 0, 1, 2, 3, 5, 8 (beginning of Fibonacci)
        case story_points
        when 0, 1
          0.1
        when 2, 3
          1
        when 5
          1.5
        when 8
          2
        else
          1 # for now we ignore other values
        end
      end
    end
  end
end
