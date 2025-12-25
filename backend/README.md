# Notio Backend Setup

This folder contains the Node.js backend for the Notio app.

## Prerequisites
1.  **Node.js**: Installed on your system.
2.  **MongoDB**: You need a running MongoDB instance.
    -   Download [MongoDB Community Server](https://www.mongodb.com/try/download/community) if you don't have it.
    -   Or use [Docker](https://www.docker.com/): `docker run -d -p 27017:27017 --name mongodb mongo`

## Setup
1.  Open a terminal in this `backend` folder.
2.  Run `npm install` to install dependencies.
3.  (Optional) Update `.env` file if your MongoDB URI is different.

## Running
-   Run `npm start` to start the server.
-   You should see `🚀 Server running on port 3000` and `✅ MongoDB Connected`.
