# frozen_string_literal: true

module Types
  module PaymentProviders
    class Pinet < Types::BaseObject
      graphql_name 'PinetProvider'

      field :id, ID, null: false
      field :key_id, String, null: false
      field :private_key, String, null: false

      field :success_redirect_url, String, null: true

      def key_id
        "#{'•' * 8}…#{object.key_id[-3..]}"
      end

      def private_key
        "#{'•' * 8}…#{object.private_key[-3..]}"
      end
    end
  end
end
