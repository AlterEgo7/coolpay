require "coolpay/version"
require 'coolpay/recipient'
require 'httparty'

module Coolpay

  API_URL = 'https://coolpay.herokuapp.com/api'

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
        body = { name: name }
      end

      response = HTTParty.get(API_URL + '/recipients', body: body,
                              headers: { :'Content-Type' => 'application/json', Authorization: "Bearer #{token}" })

      raise UnauthorizedError if response.unauthorized?

      response.parsed_response['recipients']
        .map { |h| Recipient.new(h['name'], h['id']) }
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
