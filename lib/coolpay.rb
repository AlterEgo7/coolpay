require "coolpay/version"
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

      body = { name: name }.to_json
      response = HTTParty.post(API_URL + '/recipients', body: body,
                               headers: { :'Content-Type' => 'application/json' })

      unless response.created?
        raise ApiError, 'recipient could not be created'
      end

    end

  end

  class AuthenticationError < StandardError
    def initialize(msg = 'Authentication Unsuccessful')
      super(msg)
    end
  end

  class ApiError < StandardError
  end
end
