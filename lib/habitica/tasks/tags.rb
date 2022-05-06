# frozen_string_literal: true

require 'habitica_client/restful'
require 'habitica_client/api_base'

module Habitica
  module Tasks
    class Tag < HabiticaClient::Restful
      extend Hashup

      endpoint '/tags'

      attr_accessor :name, :id, :challenge

      hashup :id, :name, :challenge

      def url
        "#{endpoint}/#{id}"
      end
    end

    class Tags < HabiticaClient::ApiBase
      include Enumerable

      endpoint '/tags'

      def each
        data.each do |tag|
          yield Tag.parse(client, tag)
        end
      end
    end

    module TagExtension
      def tags
        @tags ||= Tags.new(client)
      end
    end

    # should be included in a class with #tags and #client (so Task class)
    module TaskTagExtension
      def tag_names
        @tag_names ||= begin
          @@tags_by_id ||= client.tags.map { |t| [t.id, t.name] }.to_h
          tags.map { |id| @@tags_by_id[id] }
        end
      end

      def tag?(tag_name_or_id)
        tags.include?(tag_name_or_id) || tag_names.include?(tag_name_or_id)
      end
    end
  end
end

class HabiticaClient
  prepend Habitica::Tasks::TagExtension
  class Task
    prepend Habitica::Tasks::TaskTagExtension
  end

  class Client
    def tags
      @tags ||= Habitica::Tasks::Tags.new(self)
    end
  end
end
