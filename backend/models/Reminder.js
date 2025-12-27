const mongoose = require('mongoose');

const reminderSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
        trim: true
    },
    dateTime: {
        type: Date,
        required: true
    },
    repeat: {
        type: String,
        default: 'None' // None, Daily, Weekly
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    isActive: {
        type: Boolean,
        default: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Reminder', reminderSchema);
