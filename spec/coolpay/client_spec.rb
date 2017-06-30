require "spec_helper"

RSpec.describe Coolpay::Client do
  before do
    @client = Coolpay::Client.new
  end

  describe 'authentication' do
    it 'should have credentials present' do
      expect { @client.authenticate(nil, 'test') }.to raise_error(ArgumentError)
      expect { @client.authenticate('', 'test') }.to raise_error(ArgumentError)
      expect { @client.authenticate('test', '') }.to raise_error(ArgumentError)
      expect { @client.authenticate('test', nil) }.to raise_error(ArgumentError)
    end

    describe 'successful' do
      before do
        stub_request(:post, Coolpay::API_URL + '/login')
          .with(body: { username: 'valid-user', password: 'valid-password' }.to_json)
          .to_return(status: 200, body: { token: 'valid-token' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        @client.authenticate('valid-user', 'valid-password')
      end

      it 'should have receive authentication token' do
        expect(@client.token).to eq 'valid-token'
      end
    end

    describe 'unsuccessful' do
      before do
        stub_request(:post, Coolpay::API_URL + '/login')
          .with(body: { username: 'valid-user', password: 'valid-password' }.to_json)
          .to_return(status: 404, body: 'Internal Server Error',
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'should raise exception' do
        expect { @client.authenticate('valid-user', 'valid-password') }
          .to raise_error(Coolpay::AuthenticationError)
      end
    end
  end

  describe 'recipient addition' do
    it 'should have name present' do
      expect { @client.add_recipient('') }.to raise_error ArgumentError
      expect { @client.add_recipient(nil) }.to raise_error ArgumentError
    end

    describe 'successful' do

      before do
        stub_request(:post, Coolpay::API_URL + '/recipients')
          .with(body: { name: 'recipient' }.to_json)
          .to_return(status: 201, body: { name: 'recipient', id: '123456' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'should return new Recipient' do
        expect(@client.add_recipient('recipient').name).to eq 'recipient'
      end
    end

    describe 'unsuccessful' do
      before do
        stub_request(:post, Coolpay::API_URL + '/recipients')
          .with(body: { name: 'recipient' }.to_json)
          .to_return(status: 500)
      end

      it 'should raise ApiError' do
        expect { @client.add_recipient('recipient') }.to raise_error Coolpay::ApiError
      end
    end

  end
end
