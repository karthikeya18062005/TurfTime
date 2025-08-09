const nodemailer = require('nodemailer');

const sendOTPEmail = async (email, otp) => {
  const transporter = nodemailer.createTransport({
    service: 'Gmail',
    auth: {
      user: process.env.EMAIL_USER, 
      pass: process.env.EMAIL_PASS
    }
  });

  const mailOptions = {
    from: '"TurfTime" <no-reply@turftime.com>',
    to: email,
    subject: 'Verify your email',
    html: `<p>Your OTP is <b>${otp}</b>. It expires in 5 minutes.</p>`
  };

  try {
  await transporter.sendMail(mailOptions);
} catch (err) {
  console.error("❌ Failed to send email:", err);
  return res.status(500).json({ message: "Email send failed", error: err.message });
}
    console.log(`✅ OTP sent to ${email}`);
    return { status: 'success', message: 'OTP sent successfully' };
};

module.exports = sendOTPEmail;
