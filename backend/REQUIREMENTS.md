# Notio Backend Requirements

To enable **Real-Time Authentication** and **Data Sync**, the following services must be running:

## 1. Node.js Backend (Crucial)
You must keep the backend server running while using the app.
**Command:**
```bash
cd backend
npm start
```
*Status: I have started this for you, but if you restart VS Code, you must run it again.*

## 2. MongoDB Database (Required)
The backend needs a database to store users and notes.
**Option A: Local MongoDB (Recommended for Offline)**
- Download and Install [MongoDB Community Server](https://www.mongodb.com/try/download/community).
- Ensure the service is running.
- Default URL: `mongodb://localhost:27017/notio`

**Option B: MongoDB Atlas (Cloud)**
- Create a free account at [MongoDB Atlas](https://www.mongodb.com/atlas).
- Get your connection string (e.g., `mongodb+srv://<user>:<password>@cluster0...`).
- Update `MONGO_URI` in `backend/.env`.

## 3. Email Service (For OTPs)
To receive *actual* emails with OTP codes:
- Open `backend/.env`.
- Update `EMAIL_USER` with your Gmail address.
- Update `EMAIL_PASS` with an [App Password](https://support.google.com/accounts/answer/185833) (not your login password).
- *Without this, the OTP will only appear in the Backend Terminal logs.*
this is my app password - fsdr ejvs ggwn zkdf
and i will download the mongo db in my system