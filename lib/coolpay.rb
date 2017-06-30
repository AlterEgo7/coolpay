require "coolpay/version"

class Coolpay

  LOGIN_URL = 'https://coolpay.herokuapp.com/api/login'

  attr_reader :token

  def authenticate(username, password)

    raise ArgumentError, 'username is mandatory' if username.to_s.empty?
    raise ArgumentError, 'password is mandatory' if password.to_s.empty?

    body = { username: username, password: password }.to_json
    response = HTTParty.post(LOGIN_URL, body: body,
                             headers: { :'Content-Type' => 'application/json' })


    if !response.ok?
      raise AuthenticationError
    else
      @token = response.parsed_response['token']
    end
  end

  class AuthenticationError < StandardError
    def initialize(msg = 'Authentication Unsuccessful')
      super(msg)
    end
  end
end
