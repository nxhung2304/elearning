module Api
  module V1
    class Auth < Api::Base
      helpers do
        def token_from_header
          auth_header = headers["Authorization"] || headers["authorization"]
          return nil unless auth_header

          auth_header.split(" ").last
        end
      end

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

          if result[:token]
            present :token, result[:token]
            present :user, result[:user]
          else
            error!({ errors: result[:errors] }, 422)
          end
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

          if result[:token] && result[:user]
            present :token, result[:token]
            present :user, result[:user]
          else
            error!({ errors: result[:errors] }, 422)
          end
        end
      end

      resource :sign_out do
        desc "Sign out user and revoke JWT token"
        delete do
          token = token_from_header
          error!("Authorization token missing", 400) unless token.present?

          Warden::JWTAuth::TokenRevoker.new.call(token)
          { message: "Signed out successfully" }
        rescue JWT::DecodeError => e
          error!({ errors: e.message }, 401)
        end
      end
    end
  end
end
