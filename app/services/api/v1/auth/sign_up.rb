class Api::V1::Auth::SignUp
  def initialize(params)
    @params = params
  end

  def call
    student_role = Role.find_by(code: Role::STUDENT)
    return { errors: [ "Student role not found" ] } unless student_role

    new_user = User.new(user_params)
    new_user.roles << student_role

    if new_user.save
      token, _payload = Warden::JWTAuth::UserEncoder.new.call(new_user, :user, nil)
      { token:, user: UserEntity.represent(new_user) }
    else
      { errors: new_user.errors.full_messages }
    end
  end

  private

  def user_params
    @params.slice(:email, :password, :password_confirmation)
  end
end
