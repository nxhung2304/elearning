module API
  module V1
    class Auth < Base
      resource :sign_up do
        desc "Sign up a user (default is student role)"
        params do
          requires :email, type: String, desc: "Email"
          requires :password, type: String, desc: "Password"
        end
        post do
          new_user = User.new(email: params[:email], password: params[:password])
          new_user.roles << Role.find_by!(code: Role::STUDENT)
          if new_user.save
            token = Warden::JWTAuth::UserEncoder.new.call(new_user, :user, nil)
            { token:, user: UserEntity.represent(new_user) }
          else
            error!({ errors: new_user.errors.full_messages }, 422)
          end
        end
      end
    end
  end
end
