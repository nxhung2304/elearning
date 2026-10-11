class OtparyMailer < ApplicationMailer
  def send_otp(user)
    @user = user
    @otp = user.otp_code

    mail(to: @user.email, subject: "Your 6-Digit OTP Code")
  end
end
