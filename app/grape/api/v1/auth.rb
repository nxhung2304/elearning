module Api
  module V1
    class Auth < Api::Base
      helpers do
        def token_from_header
          auth_header = headers["Authorization"] || headers["authorization"]
          return nil unless auth_header

          auth_header.split(" ").last
        end

        def present_auth_result(result)
          if result[:access_token] && result[:refresh_token] && result[:user]
            present result, with: AuthEntity
          else
            error!({ errors: result[:errors] }, result[:status] || 422)
          end
        end
      end

      namespace :auth do
        resource :sign_up do
          desc "Sign up a user (default is student role)"
          params do
            requires :email, type: String, desc: "Email"
            requires :password, type: String, desc: "Password"
            requires :password_confirmation, type: String, desc: "Password confirmation"
            optional :name, type: String, desc: "Name"
          end
          post do
            result = Api::V1::Auth::SignUp.new(params).call
            present_auth_result(result)
          end
        end

        resource :sign_in do
          desc "Sign in with email and password"
          params do
            requires :email, type: String, desc: "Email"
            requires :password, type: String, desc: "Password"
          end
          post do
            result = Api::V1::Auth::SignIn.new(params).call

            present_auth_result(result)
          end
        end

        resource :sign_out do
          desc "Sign out user and revoke JWT token"
          delete do
            authenticate!

            token = token_from_header
            error!("Authorization token missing", 400) unless token.present?

            Warden::JWTAuth::TokenRevoker.new.call(token)
            { message: "Signed out successfully" }
          rescue JWT::DecodeError => e
            error!({ errors: e.message }, 401)
          end
        end

        resource :refresh do
          desc "Refresh new token"
          params do
            requires :refresh_token, type: String, desc: "The custom refresh token"
          end
          post do
            result = Api::V1::Auth::Refresh.new(params[:refresh_token]).call
            present_auth_result(result)
          end
        end
      end
    end
  end
end
