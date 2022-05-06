# frozen_string_literal: true

require 'time'
require 'active_support/all' # just for the months/years extension!

module Habitica
  module Tasks
    module Occurences
      def real_start_date
        @real_start_date ||= real_date(start_date)
      end

      def real_date(date)
        candidate = date.in_time_zone('Europe/Paris')
        if candidate.to_date.to_time == candidate
          candidate.to_date
        else
          # weird handling of daylight saving shift in
          # habitica: it stores start_date with
          # incorrect shift from local time: "at the
          # moment of the creation" instead of "at the
          # time of the start_date".
          candidate.to_date + 1
        end
      end

      # @return [Enumerable<Date>] list of dates at which the task occurs
      def occurences(&block)
        return to_enum(:occurences) unless block_given?

        return [] unless daily?

        case frequency
        when 'daily'
          (0..).each { |i| yield real_start_date + every_x * i }
        when 'yearly'
          (0..).each { |i| yield real_start_date.next_year(every_x * i) }
        when 'weekly'

          (0..).each do |i|
            (1..7).each do |j|
              candidate = real_start_date + (every_x * i).weeks + j.days
              # HACK: leverage repeat structure {"m"=>false, "t"=>false, "w"=>true, "th"=>false, "f"=>false, "s"=>false, "su"=>false}
              yield candidate if repeat.values[candidate.cwday - 1]
            end
          end
        when 'monthly'
          if days_of_month.any?
            (0..).each do |i|
              candidate = real_start_date + (every_x * i).month
              matching = days_of_month.include?(candidate.day)
              yield candidate if matching
            end
          else
            # ok let's use what habitica api is providing us to avoid doing the heavy lifting ourselves
            # it means we provide a limited history and limited occurence prevision though!
            (history.select { |d| d['isDue'] }.map { |d| Time.at(d['date'] / 1000).localtime.to_date } + next_due.map { |s| Time.parse(s).localtime.to_date }).uniq.each(&block)
          end
        else
          raise NotImplementedError
        end
      end

      # @return [Date] last occurence that was strictly before today (or the `before` parameter)
      def last_occurence(before: Date.today)
        occurences.take_while do |occurence|
          occurence < before
        end.last
      end

      # @return [Date] first occurence happening after today
      def next_occurence(after: Date.today)
        occurences.drop_while do |occurence|
          occurence < after
        end.first
      end

      def last_occurence_completed?
        history.select { |h| h['isDue'] }&.last&.dig('completed')
      end
    end
  end
end

HabiticaClient::Task.prepend(Habitica::Tasks::Occurences)
