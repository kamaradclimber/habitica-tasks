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
  end
end

class HabiticaClient
  prepend Habitica::Tasks::TagExtension
end
