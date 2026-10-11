require "test_helper"

class OtparyMailerTest < ActionMailer::TestCase
  test "send_otp" do
    user = create(:user)
    user.generate_otp!

    email = OtparyMailer.send_otp(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ user.email ], email.to
    assert_equal "Your 6-Digit OTP Code", email.subject
    assert_match user.otp_code, email.body.encoded
  end
end
