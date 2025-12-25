const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer'); // Use for real email
const User = require('../models/User');
const auth = require('../middleware/auth');

// Mock Transport (Replace with real SMTP for production)
// const transporter = nodemailer.createTransport({ ... });

// Generate 6-digit OTP
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// @route   POST /api/auth/register
// @desc    Register user & send OTP
// @access  Public
router.post('/register', async (req, res) => {
    const { name, email, password, username } = req.body;

    try {
        let user = await User.findOne({ email });
        if (user && user.isVerified) {
            return res.status(400).json({ msg: 'User already exists' });
        }

        // If user exists but not verified, update them. Else create new.
        if (!user) {
            user = new User({
                name,
                email,
                username: username || email.split('@')[0],
                passwordHash: password, // Will hash below
                isVerified: false
            });
        } else {
            // Update existing unverified user details
            user.name = name;
            user.username = username || user.username;
            user.passwordHash = password;
        }

        // Hash Password
        const salt = await bcrypt.genSalt(10);
        user.passwordHash = await bcrypt.hash(password, salt);

        // Generate OTP
        const otp = generateOTP();
        user.otp = otp;
        user.otpExpires = Date.now() + 10 * 60 * 1000; // 10 mins

        await user.save();

        // Email Configuration (Gmail)
        const transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS
            }
        });

        const mailOptions = {
            from: `"Notio App" <${process.env.EMAIL_USER}>`,
            to: email,
            subject: 'Notio - Your OTP Code',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
                    <h2 style="color: #4CAF50; text-align: center;">Notio Verification</h2>
                    <p>Hello <b>${name}</b>,</p>
                    <p>Your One-Time Password (OTP) for account verification is:</p>
                    <div style="text-align: center; margin: 20px 0;">
                        <span style="font-size: 24px; font-weight: bold; padding: 10px 20px; background-color: #f4f4f4; border-radius: 5px; letter-spacing: 2px;">
                            ${otp}
                        </span>
                    </div>
                    <p>This code is valid for 10 minutes. Please do not share this code with anyone.</p>
                    <p>If you didn't request this, you can ignore this email.</p>
                    <br>
                    <p style="font-size: 12px; color: #888; text-align: center;">&copy; ${new Date().getFullYear()} Notio App. All rights reserved.</p>
                </div>
            `
        };

        // Send Email
        await transporter.sendMail(mailOptions);
        console.log(`✅ Email sent to ${email}`);

        res.json({ msg: 'OTP sent to email', email: email });

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   POST /api/auth/verify-otp
// @desc    Verify OTP and activate account
// @access  Public
router.post('/verify-otp', async (req, res) => {
    const { email, otp } = req.body;

    try {
        let user = await User.findOne({ email });

        if (!user) return res.status(400).json({ msg: 'User not found' });
        if (user.isVerified) return res.status(400).json({ msg: 'User already verified' });

        if (user.otp !== otp) {
            return res.status(400).json({ msg: 'Invalid OTP' });
        }

        if (Date.now() > user.otpExpires) {
            return res.status(400).json({ msg: 'OTP Expired' });
        }

        user.isVerified = true;
        user.otp = undefined;
        user.otpExpires = undefined;
        await user.save();

        // Return Token immediately
        const payload = { user: { id: user.id } };
        jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' }, (err, token) => {
            if (err) throw err;
            res.json({ token, user: { id: user.id, name: user.name, email: user.email, username: user.username } });
        });

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   POST /api/auth/login
// @desc    Authenticate user & get token
// @access  Public
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        let user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ msg: 'Invalid Credentials' });
        }

        if (!user.isVerified) {
            return res.status(400).json({ msg: 'Account not verified. Please verify OTP first.' });
        }

        const isMatch = await bcrypt.compare(password, user.passwordHash);
        if (!isMatch) {
            return res.status(400).json({ msg: 'Invalid Credentials' });
        }

        const payload = { user: { id: user.id } };

        jwt.sign(
            payload,
            process.env.JWT_SECRET,
            { expiresIn: '7d' },
            (err, token) => {
                if (err) throw err;
                res.json({ token, user: { id: user.id, name: user.name, email: user.email, username: user.username, bio: user.bio, profileImage: user.profileImage, frameIndex: 0, avatarIndex: 0 } });
            }
        );
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-passwordHash -otp -otpExpires');
        res.json(user);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
