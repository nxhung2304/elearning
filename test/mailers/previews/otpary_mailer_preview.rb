# Preview all emails at http://localhost:3000/rails/mailers/otpary_mailer
class OtparyMailerPreview < ActionMailer::Preview
  def send_otp
    user = FactoryBot.create(:user)
    user.generate_otp!

    OtparyMailer.send_otp(user)
  end
end
