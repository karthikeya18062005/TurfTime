const express = require("express");
const router = express.Router();
const { register, login,verifyOTP,resendOTP,verifyOtpLogin,resendOtpLogin,forgotPassword,resetPassword  } = require("../controllers/authController");

router.post("/register", register);
router.post("/login", login);
router.post('/verify-otp', verifyOTP);
router.post('/resend-otp', resendOTP);
router.post("/verify-otp-login", verifyOtpLogin);
router.post("/resend-otp-login", resendOtpLogin);
router.post("/forgot-password", forgotPassword);
router.post("/reset-password", resetPassword);


module.exports = router;
