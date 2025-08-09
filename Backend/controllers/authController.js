const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User");
const sendOTPEmail = require('../utils/sendOTP');
const crypto = require('crypto');

const register = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    const existingUser = await User.findOne({ email });

    // --- LOGIC CHANGE STARTS HERE ---

    if (existingUser) {
      // Case 1: User exists and is already verified. Block them.
      if (existingUser.isVerified) {
        return res.status(400).json({ message: "This email is already registered." });
      }
      
      // Case 2: User exists but is NOT verified. Update them and resend OTP.
      const hashedPassword = await bcrypt.hash(password, 10);
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');
      const otpExpiry = Date.now() + 5 * 60 * 1000; // 5 mins

      existingUser.name = name;
      existingUser.password = hashedPassword;
      existingUser.otp = hashedOtp;
      existingUser.otpExpiry = otpExpiry;
      // You can update the role if you allow it to be changed on re-registration
      // existingUser.role = role; 

      await existingUser.save();
      await sendOTPEmail(email, otp);

      // Return 200 OK since we updated an existing resource
      return res.status(200).json({ message: "New OTP sent. Please verify your email." });

    } else {
      // Case 3: User does not exist. Create a new one.
      const hashedPassword = await bcrypt.hash(password, 10);
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');
      const otpExpiry = Date.now() + 5 * 60 * 1000;

      await User.create({
        name,
        email,
        password: hashedPassword,
        role,
        otp: hashedOtp,
        otpExpiry
      });

      await sendOTPEmail(email, otp);

      // Return 201 Created for a new resource
      return res.status(201).json({ message: "User registered. Verify your email with the OTP sent." });
    }
    // --- LOGIC CHANGE ENDS HERE ---

  } catch (err) {
    res.status(500).json({ message: "Registration failed", error: err.message });
  }
};


const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email }).select("+password");

    if (!user) return res.status(400).json({ message: "Invalid credentials" });
    if (!user.isVerified)
      return res.status(401).json({ message: "Please verify your email first" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.status(400).json({ message: "Invalid credentials" });

    // ✅ Password valid → now send OTP for 2FA
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const hashedOtp = crypto.createHash("sha256").update(otp).digest("hex");
    const otpExpiry = Date.now() + 5 * 60 * 1000; // 5 mins

    user.otp = hashedOtp;
    user.otpExpiry = otpExpiry;
    await user.save();

    await sendOTPEmail(email, otp);
    res.status(200).json({ message: "OTP sent. Please verify to complete login." });
  } catch (err) {
    console.error("🔥 Login error:", err);
    res.status(500).json({ message: "Login failed", error: err.message });
  }
};

// 2FA Login Step-2: Verify OTP and issue token
const verifyOtpLogin = async (req, res) => {
  try {
    const { email, otp } = req.body;
    const user = await User.findOne({ email });

    if (!user || !user.otp || !user.otpExpiry)
      return res.status(400).json({ message: "No login OTP found. Please login again." });

    const hashedOtp = crypto.createHash("sha256").update(otp).digest("hex");

    if (user.otp !== hashedOtp)
      return res.status(400).json({ message: "Invalid OTP" });

    if (Date.now() > user.otpExpiry)
      return res.status(400).json({ message: "OTP expired" });

    // ✅ OTP verified, issue token and clear OTP fields
    user.otp = undefined;
    user.otpExpiry = undefined;
    await user.save();

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET || "default_secret",
      { expiresIn: "7d" }
    );

    res.status(200).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        role: user.role
      }
    });
  } catch (err) {
    console.error("2FA OTP Verify Error:", err);
    res.status(500).json({ message: "OTP verification failed", error: err.message });
  }
};


const verifyOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: "User not found" });
    }

    const hashedOtp = crypto.createHash("sha256").update(otp).digest("hex");

    if (user.otp !== hashedOtp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    if (user.otpExpiry < Date.now()) {
      return res.status(400).json({ message: "OTP expired" });
    }

    user.isVerified = true;
    user.otp = undefined;
    user.otpExpiry = undefined;
    await user.save();

    res.status(200).json({ message: "OTP verified successfully" });

  } catch (err) {
    console.error("OTP Verification Error:", err);
    res.status(500).json({ message: "OTP verification failed", error: err.message });
  }
};
// Add this to your authController.js

const resendOTP = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({ message: "User not found." });
    }

    if (user.isVerified) {
      return res.status(400).json({ message: "This email is already verified." });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const hashedOtp = crypto.createHash("sha256").update(otp).digest("hex");
    const otpExpiry = Date.now() + 5 * 60 * 1000; // 5 mins

    user.otp = hashedOtp;
    user.otpExpiry = otpExpiry;
    await user.save();

    await sendOTPEmail(email, otp); // ✅ Don't forget to import the function

    res.status(200).json({ message: "A new OTP has been sent to your email." });

  } catch (err) {
    console.error("Resend OTP Error:", err);
    res.status(500).json({ message: "Failed to resend OTP.", error: err.message });
  }
};
const resendOtpLogin = async (req, res) => {
  const { email } = req.body;

  if (!email) return res.status(400).json({ message: "Email is required" });

  const user = await User.findOne({ email, isVerified: true });
  if (!user) return res.status(404).json({ message: "User not found or not verified" });

  // Generate OTP
  const otp = generateOtp();
  const hashedOtp = await bcrypt.hash(otp, 10);

  user.otp = hashedOtp;
  user.otpExpiry = Date.now() + 5 * 60 * 1000; // 5 mins
  await user.save();

  // Send OTP to email
  await sendEmail(email, "Your TurfTime Login OTP", `Your OTP is: ${otp}`);

  res.status(200).json({ message: "OTP resent to your email" });
};

// POST /api/auth/forgot-password
const forgotPassword = async (req, res) => {
  try {
    const email = req.body.email?.trim().toLowerCase();
    if (!email) return res.status(400).json({ message: "Email is required" });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const hashedOtp = crypto.createHash("sha256").update(otp).digest("hex");

    user.resetPasswordOtp = hashedOtp;
    user.resetPasswordOtpExpiry = Date.now() + 5 * 60 * 1000;
    await user.save();

    await sendOTPEmail(email, otp);

    return res.status(200).json({ message: "OTP sent to email for password reset" });
  } catch (error) {
    console.error("Forgot Password Error:", error);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};


// POST /api/auth/reset-password
const resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword) {
      return res.status(400).json({ message: "All fields are required" });
    }

    const user = await User.findOne({ email }).select("+password");
    if (!user) return res.status(404).json({ message: "User not found" });

    const hashedOtp = crypto.createHash("sha256").update(otp).digest("hex");

    if (
      user.resetPasswordOtp !== hashedOtp ||
      user.resetPasswordOtpExpiry < Date.now()
    ) {
      return res.status(400).json({ message: "Invalid or expired OTP" });
    }

    user.password = await bcrypt.hash(newPassword, 10);
    user.resetPasswordOtp = undefined;
    user.resetPasswordOtpExpiry = undefined;
    await user.save();

    return res.status(200).json({ message: "Password reset successful" });
  } catch (error) {
    console.error("Reset Password Error:", error);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};

// Don't forget to export it
module.exports = { register, login, verifyOTP, resendOTP, verifyOtpLogin, resendOtpLogin, forgotPassword, resetPassword };