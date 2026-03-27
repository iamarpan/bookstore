# Real-time Chat WebSocket Server

This document describes the WebSocket server setup for real-time chat functionality.

## Architecture

The WebSocket server uses Socket.IO and runs separately from the main REST API (which is deployed on Vercel serverless).

```
┌─────────────────┐     ┌─────────────────┐
│  Mobile Apps    │────▶│  Vercel REST    │
│  (iOS/Android)  │     │      API        │
└────────┬────────┘     └─────────────────┘
         │
         │ WebSocket
         ▼
┌─────────────────┐
│  Socket.IO      │
│    Server       │
│ (Railway/Fly.io)│
└─────────────────┘
```

## Local Development

Run the socket server locally:

```bash
npm run dev:socket
```

This starts the WebSocket server on port 3001 (or `SOCKET_PORT` env var).

## Deployment

### Option 1: Railway

1. Create a new Railway project
2. Connect your GitHub repository
3. Set the start command to `npm run start:socket`
4. Configure environment variables:
   - `JWT_ACCESS_SECRET` - Same as main API
   - `DATABASE_URL` - Database connection string
   - `PORT` - Railway sets this automatically

### Option 2: Fly.io

```bash
flyctl launch --config fly.socket.toml
flyctl secrets set JWT_ACCESS_SECRET=your-secret
flyctl secrets set DATABASE_URL=your-db-url
flyctl deploy --config fly.socket.toml
```

### Option 3: Render

1. Create a new Web Service
2. Set build command: `npm run build`
3. Set start command: `npm run start:socket`
4. Add environment variables

## Events

### Client → Server

| Event | Payload | Description |
|-------|---------|-------------|
| `join_chat` | `transactionId: string` | Subscribe to chat room |
| `leave_chat` | `transactionId: string` | Unsubscribe from chat |
| `typing` | `{ transactionId, isTyping }` | Typing indicator |
| `message_read` | `{ transactionId }` | Mark messages as read |

### Server → Client

| Event | Payload | Description |
|-------|---------|-------------|
| `new_message` | `Message` object | Real-time message |
| `message_notification` | `{ transactionId, message }` | Push notification data |
| `user_typing` | `{ userId, transactionId, isTyping }` | Typing indicator |
| `messages_read` | `{ userId, transactionId }` | Read receipt |

## Authentication

The socket server uses JWT authentication. Clients must provide the access token in the socket handshake:

```javascript
// Client connection
const socket = io(SOCKET_URL, {
  auth: { token: accessToken }
});
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `PORT` | Server port (default: 3001) | No |
| `SOCKET_PORT` | Alternative to PORT | No |
| `JWT_ACCESS_SECRET` | JWT signing secret | Yes |
| `DATABASE_URL` | Prisma database URL | Yes |
| `NODE_ENV` | Environment (development/production) | No |
