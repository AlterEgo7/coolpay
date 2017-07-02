require "coolpay/version"
require 'coolpay/recipient'
require 'httparty'

module Coolpay

  API_URL = 'https://coolpay.herokuapp.com/api'


  # TODO: Refactor validations and checks into methods
  class Client

    attr_reader :token

    def authenticate(username, password)
      raise ArgumentError, 'username is mandatory' if username.to_s.empty?
      raise ArgumentError, 'password is mandatory' if password.to_s.empty?

      body = { username: username, password: password }.to_json
      response = HTTParty.post(API_URL + '/login', body: body,
                               headers: { :'Content-Type' => 'application/json' })

      if !response.ok?
        raise AuthenticationError
      else
        @token = response.parsed_response['token']
      end
    end

    def add_recipient(name)
      raise ArgumentError, 'recipient name is mandatory' if name.to_s.empty?
      raise UnauthorizedError if @token.nil?

      body = { name: name }.to_json
      response = HTTParty.post(API_URL + '/recipients', body: body,
                               headers: { :'Content-Type' => 'application/json', Authorization: "Bearer #{token}" })

      unless response.created?
        raise ApiError, 'recipient could not be created'
      end

      if response.unauthorized?
        raise UnauthorizedError
      end

      response_body = response.parsed_response
      Recipient.new(response_body['name'], response_body['id'])
    end

    def get_recipients(name = nil)
      raise UnauthorizedError if @token.nil?

      unless name.nil?
        body = { name: name }.to_json
      end

      response = HTTParty.get(API_URL + '/recipients', body: body,
                              headers: { :'Content-Type' => 'application/json', Authorization: "Bearer #{token}" })

      raise UnauthorizedError if response.unauthorized?

      response.parsed_response['recipients']
        .map { |h| Recipient.new(h['name'], h['id']) }
    end

    def create_payment(amount, currency, recipient_id)
      raise UnauthorizedError if @token.nil?
      raise ArgumentError 'Amount must be numeric' unless amount.is_a? Numeric
      raise ArgumentError 'Currency must be a string' unless currency.is_a? String
      raise ArgumentError 'Recipient ID must be a string' unless recipient_id.is_a? String

      body = { amount: amount, currency: currency, recipient_id: recipient_id }.to_json

      response = HTTParty.post(API_URL + '/payments', body: body, headers: { :'Content-Type' => 'application/json',
                                                                             Authorization: "Bearer #{token}" })

      raise UnauthorizedError if response.unauthorized?
      raise ArgumentError, 'Recipient does not exist' if response.unprocessable_entity?

      Payment.new(response.parsed_response['payment'])
    end

    def get_payments
      raise UnauthorizedError if @token.nil?

      response = HTTParty.get(API_URL + '/payments', headers: { :'Content-Type' => 'application/json',
                                                                 Authorization: "Bearer #{token}" })

      raise UnauthorizedError if response.unauthorized?

      response.parsed_response['payments'].map{ |options| Payment.new(options) }
    end

  end

  class AuthenticationError < StandardError
    def initialize(msg = 'Authentication Unsuccessful')
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
