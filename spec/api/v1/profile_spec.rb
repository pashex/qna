require 'rails_helper'

describe 'Profiles API', type: :request do
  let(:headers) { { 'CONTENT-TYPE' => 'application/json',
                    'ACCEPT' => 'application/json' } }

  describe 'GET /api/v1/profiles/me' do
    let(:api_path) { '/api/v1/profiles/me' }
    let(:me) { create :user }
    let(:access_token) { create :access_token, resource_owner_id: me.id }

    it_behaves_like 'API authorizable' do
      let(:method) { :get }
    end

    context 'authorized' do
      let(:user_json) { json['user'] }

      before do
        get api_path, params: { access_token: access_token.token }, headers: headers
      end

      it 'returns public fields of user' do
        %w[id email admin created_at updated_at].each do |attr|
          expect(user_json[attr]).to eq me.send(attr).as_json
        end
      end

      it 'doesn`t return private fields of user' do
        %w[password encrypted_password].each do |attr|
          expect(user_json).to_not have_key(attr)
        end
      end
    end
  end
end
