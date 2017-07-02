module Helpers
  def authenticate_client
    stub_request(:post, Coolpay::API_URL + '/login')
      .with(body: { username: 'valid-user', apikey: 'valid-apikey' }.to_json)
      .to_return(status: 200, body: { token: 'valid-token' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    @client.authenticate('valid-user', 'valid-apikey')
  end
end