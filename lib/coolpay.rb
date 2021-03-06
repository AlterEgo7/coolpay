require "coolpay/version"
require 'coolpay/recipient'
require 'coolpay/payment'
require 'httparty'

module Coolpay

  API_URL = 'https://coolpay.herokuapp.com/api'

  class Client

    attr_accessor :token

    def authenticate(username, apikey)
      validate_login_arguments(apikey, username)

      body = { username: username, apikey: apikey }.to_json
      response = HTTParty.post(API_URL + '/login', body: body,
                               headers: { :'Content-Type' => 'application/json' })

      if !response.ok?
        raise AuthenticationError
      else
        @token = response.parsed_response['token']
      end
    end

    def add_recipient(name)
      validate_recipient_arguments(name)
      raise UnauthorizedError if @token.nil?

      body = { recipient: { name: name } }.to_json
      response = HTTParty.post(API_URL + '/recipients', body: body,
                               headers: { :'Content-Type' => 'application/json', Authorization: "Bearer #{token}" })

      unless response.created?
        raise ApiError, 'recipient could not be created'
      end

      if response.unauthorized?
        raise UnauthorizedError
      end

      recipient_attributes = response.parsed_response['recipient']
      Recipient.new(recipient_attributes['name'], recipient_attributes['id'])
    end

    def get_recipients(name = nil)
      raise UnauthorizedError if @token.nil?

      unless name.nil?
        query = { name: name }
      end

      response = HTTParty.get(API_URL + '/recipients', query: query,
                              headers: { :'Content-Type' => 'application/json', Authorization: "Bearer #{token}" })

      raise UnauthorizedError if response.unauthorized?

      response.parsed_response['recipients']
        .map { |h| Recipient.new(h['name'], h['id']) }
    end

    def create_payment(amount, currency, recipient_id)
      raise UnauthorizedError if @token.nil?
      validate_payment_arguments(amount, currency, recipient_id)

      body = { payment: { amount: amount.to_f, currency: currency, recipient_id: recipient_id } }.to_json

      response = HTTParty.post(API_URL + '/payments', body: body, headers: { :'Content-Type' => 'application/json',
                                                                             Authorization: "Bearer #{token}" })

      raise UnauthorizedError if response.unauthorized?
      raise ArgumentError, 'Recipient does not exist' if response.unprocessable_entity?
      raise ApiError, 'Something went wrong' if response.code == 400 || response.internal_server_error?

      Payment.new(response.parsed_response['payment'])
    end

    def get_payments
      raise UnauthorizedError if @token.nil?

      response = HTTParty.get(API_URL + '/payments', headers: { :'Content-Type' => 'application/json',
                                                                Authorization: "Bearer #{token}" })

      raise UnauthorizedError if response.unauthorized?

      response.parsed_response['payments'].map { |options| Payment.new(options) }
    end

    private

    def validate_login_arguments(apikey, username)
      raise ArgumentError, 'username is mandatory' if username.to_s.empty?
      raise ArgumentError, 'apikey is mandatory' if apikey.to_s.empty?
    end

    def validate_payment_arguments(amount, currency, recipient_id)
      raise ArgumentError 'Amount must be numeric' unless amount.to_f > 0
      raise ArgumentError 'Currency must be a string' if currency.to_s.empty?
      raise ArgumentError 'Recipient ID must be a string' if recipient_id.to_s.empty?
    end

    def validate_recipient_arguments(name)
      raise ArgumentError, 'recipient name is mandatory' if name.to_s.empty?
    end

  end

  class AuthenticationError < StandardError
    def initialize(msg = 'Authentication Failed')
      super(msg)
    end
  end

  class UnauthorizedError < StandardError
    def initialize(msg = 'Token cannot be authorized')
      super(msg)
    end
  end

  class ApiError < StandardError
  end
end
