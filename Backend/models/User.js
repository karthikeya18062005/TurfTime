const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: String,
  email: { type: String, required: true, unique: true },
  phone: String,
  role: { type: String, enum: ['user', 'admin','turfOwner'], default: 'user' },
  password: {
    type: String,
    required: true,
    select: false,
  },
  otp: String, // ✅ Needed for OTP verification
  otpExpiry: Date, // ✅ Stores OTP expiration time
  isVerified: { type: Boolean, default: false }, // ✅ Track email verification
  resetPasswordOtp: String,
  resetPasswordOtpExpiry: Date,

});

module.exports = mongoose.model('User', userSchema);
