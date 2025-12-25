const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    passwordHash: { type: String, required: true },
    username: { type: String, unique: true },
    bio: { type: String, default: '' },
    profileImage: { type: String, default: '' }, // URL or Base64
    isVerified: { type: Boolean, default: false },
    otp: { type: String }, // Temporary OTP storage
    otpExpires: { type: Date },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', UserSchema);
