# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

module NewRelic
  module Agent
    module Datastores
      module Mongo
        module MetricTranslator
          def self.metrics_for(name, payload, request_type = :web)
            payload = {} if payload.nil?

            collection = payload[:collection]

            if collection == '$cmd' && payload[:selector]
              name_and_collection = payload[:selector].first
              name, collection = name_and_collection if name_and_collection
            end

            if self.find_one?(name, payload)
              name = 'findOne'
            elsif self.find_and_remove?(name, payload)
              name = 'findAndRemove'
            elsif self.find_and_modify?(name, payload)
              name = 'findAndModify'
            elsif self.create_index?(name, payload)
              name = 'createIndex'
              collection = self.collection_name_from_index(payload)
            elsif self.drop_indexes?(name, payload)
              name = 'dropIndexes'
            elsif self.drop_index?(name, payload)
              name = 'dropIndex'
            elsif self.re_index?(name, payload)
              name = 'reIndex'
              collection = payload[:selector][:reIndex]
            end

            build_metrics(name, collection, request_type)
          end

          def self.build_metrics(name, collection, request_type = :web)
            default_metrics = [
              "Datastore/statement/MongoDB/#{collection}/#{name}",
              "Datastore/operation/MongoDB/#{name}",
              'ActiveRecord/all'
            ]

            if request_type == :web
              default_metrics << 'Datastore/allWeb'
            else
              default_metrics << 'Datastore/allOther'
            end

            default_metrics
          end

          def self.find_one?(name, payload)
            name == :find && payload[:limit] == -1
          end

          def self.find_and_modify?(name, payload)
            name == :findandmodify
          end

          def self.find_and_remove?(name, payload)
            name == :findandmodify && payload[:selector] && payload[:selector][:remove]
          end

          def self.create_index?(name, payload)
            name == :insert && payload[:collection] == "system.indexes"
          end

          def self.drop_indexes?(name, payload)
            name == :deleteIndexes && payload[:selector] && payload[:selector][:index] == "*"
          end

          def self.drop_index?(name, payload)
            name == :deleteIndexes
          end

          def self.re_index?(name, payload)
            name == :reIndex && payload[:selector] && payload[:selector][:reIndex]
          end

          def self.collection_name_from_index(payload)
            if payload[:documents] && payload[:documents].first[:ns]
              payload[:documents].first[:ns].split('.').last
            else
              'system.indexes'
            end
          end

        end

      end
    end
  end
end
