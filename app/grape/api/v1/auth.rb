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
            render_errors!(result)
          end
        end

        def render_errors!(result)
          error!({ errors: result[:errors] }, result[:status] || 422)
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

            status 200
            present_auth_result(result)
          end
        end

        resource :sign_out do
          desc "Sign out user and revoke JWT token"
          params do
            requires :refresh_token, type: String, desc: "The custom refresh token"
          end
          delete do
            authenticate!

            digest = Digest::SHA256.hexdigest(params[:refresh_token])
            current_user.refresh_tokens.active.find_by(token_digest: digest)&.update!(revoked_at: Time.current)

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

        resource :forgot_password do
          desc "Send 6-digit OTP to email"
          params do
            requires :email, type: String, desc: "User email address"
          end
          post do
            result = Api::V1::Auth::SendOtp.new(params[:email]).call

            if result && result[:errors]
              render_errors!(result)
            else
              { message: "OTP sent to email successfully." }
            end
          end
        end

        resource :vertify_otp do
          desc "Vertify OTP"
          params do
            requires :email, type: String, desc: "Email used"
            requires :otp_code, type: String, desc: "The 6-digit code received"
          end
          post do
            result = Api::V1::Auth::VertifyOtp.new(params[:email], params[:otp_code]).call

            if result && result[:errors]
              render_errors!(result)
            else
              { message: "Vertify otp successfully" }
            end
          end
        end
      end
    end
  end
end
