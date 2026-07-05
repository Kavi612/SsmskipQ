# SSM SkipQ

**Pre-Order · Pick Up · Enjoy** — a campus canteen pre-ordering app for SSM Institute of Engineering and Technology.

Students browse the menu, build a cart, pay (mock online or at counter), and track orders live. Managers handle incoming orders, menu items, ordering windows, and feedback.

---

## Project structure

```
skipQ/
├── ssm-skipq-backend/     # Express + MongoDB + Socket.io API
├── ssm-skipq-frontend/    # React + Vite PWA
└── pictures/              # Source logos and food photos
```

---

## Tech stack

| Layer | Technologies |
|-------|----------------|
| **Frontend** | React 19, Vite, TypeScript, React Router, CSS Modules, Framer Motion, lucide-react, Socket.io client, vite-plugin-pwa |
| **Backend** | Node.js, Express 5, Mongoose, JWT, Socket.io, Multer, Cloudinary |
| **Database** | MongoDB Atlas |

---

## Features

### Student
- Tap-to-continue splash with slide-up transition to Welcome screen
- Register / Login tabs (mobile-only identity, no password)
- Browse menu, cart, checkout, live order tracking
- Menu browse with categories, search, veg/non-veg filter
- Cart and checkout (Google Pay mock, PhonePe mock, pay at counter)
- Daily order tokens (A001, A002, …)
- Live order status updates and in-app toasts
- Order history, **Reorder**, and post-collection feedback (1–5 stars)
- Ordering window awareness (closed state when outside hours)
- Installable PWA on mobile

### Manager
- Login with manager ID + password
- Live orders list with status flow: Accept → Preparing → Ready → Collected
- Payment received toggle for counter orders
- Call Student (`tel:` link + number fallback)
- Menu CRUD with Cloudinary image upload
- Ordering window settings (IST)
- Feedback dashboard

---

## Prerequisites

- **Node.js 18+**
- **MongoDB Atlas** cluster (or local MongoDB)
- **Cloudinary** account (menu image uploads; required for manager menu management)

---

## Local setup

### 1. Backend

```bash
cd ssm-skipq-backend
npm install
```

Copy the example env file and fill in your values:

```bash
cp .env.example .env   # Windows: copy .env.example .env
```

| Variable | Description |
|----------|-------------|
| `MONGODB_URI` | Atlas connection string |
| `CLIENT_URL` | `http://localhost:5173` for local dev |
| `JWT_SECRET` | Long random string |
| `CLOUDINARY_*` | Cloudinary cloud name, API key, secret |

Test the database connection:

```bash
npm run test:db
```

Seed data (first time only):

```bash
npm run seed          # Categories + menu items
npm run seed:manager  # Default manager account
```

Start the API:

```bash
npm run dev
```

API runs at **http://localhost:5000**

### 2. Frontend

```bash
cd ssm-skipq-frontend
npm install
```

```bash
cp .env.example .env   # Windows: copy .env.example .env
```

Set:

```env
VITE_API_URL=http://localhost:5000
```

Start the app:

```bash
npm run dev
```

App runs at **http://localhost:5173**

---

## Default credentials

| Role | Credentials |
|------|-------------|
| **Student** | Register with name + mobile, or Login with mobile only (e.g. `9876543210`) |
| **Manager** | `SSM001` / `manager123` (after `npm run seed:manager`) |

---

## Useful commands

### Backend (`ssm-skipq-backend`)

| Command | Description |
|---------|-------------|
| `npm run dev` | Start API with nodemon |
| `npm start` | Start API (production) |
| `npm run test:db` | Test MongoDB connection |
| `npm run seed` | Seed categories and menu |
| `npm run seed:manager` | Create default manager |

### Frontend (`ssm-skipq-frontend`)

| Command | Description |
|---------|-------------|
| `npm run dev` | Development server |
| `npm run build` | Production build + PWA + icons |
| `npm run preview` | Preview production build |
| `npm run lint` | ESLint |
| `npm run generate:icons` | Regenerate PWA icons from `logo-square.png` |

---

## API overview

```
GET  /api/health

POST /api/auth/student-register   { name, mobile }
POST /api/auth/student-login      { mobile }
POST /api/auth/manager-login
GET  /api/auth/me

GET  /api/menu/categories
GET  /api/menu/items
GET  /api/menu/manager/items
POST /api/menu/items              (manager, multipart)
PATCH/DELETE menu item routes     (manager)

POST /api/orders                  (student)
GET  /api/orders                  (student)
GET  /api/orders/manager          (manager)
PATCH /api/orders/:id/status      (manager)
PATCH /api/orders/:id/payment     (manager)
POST /api/orders/:id/feedback     (student)
GET  /api/orders/feedback/manager (manager)

GET  /api/settings/ordering-window
PATCH /api/settings/ordering-window (manager)
```

### Socket.io events

| Event | Description |
|-------|-------------|
| `join:student` | Student joins personal room |
| `join:manager` | Manager joins orders room |
| `order:created` | New order (manager) |
| `order:updated` | Status/payment change |
| `settings:ordering-window` | Window times updated |

---

## Deployment

### Backend (Render)

Set environment variables from `.env.example`:

```env
MONGODB_URI=...
CLIENT_URL=https://your-app.vercel.app,http://localhost:5173
JWT_SECRET=...
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
```

Build command: `npm install`  
Start command: `npm start`

### Frontend (Vercel)

```env
VITE_API_URL=https://your-api.onrender.com
```

Build command: `npm run build`  
Output directory: `dist`

Ensure `CLIENT_URL` on the backend includes your Vercel URL so CORS and Socket.io work.

---

## Troubleshooting

### `bad auth : authentication failed`

Atlas rejected the username or password in `MONGODB_URI`.

1. Atlas → **Database Access** → edit user → reset password
2. Atlas → **Connect** → **Drivers** → copy connection string
3. Replace `<password>` and paste into `.env`
4. If the password contains `@ # / : ?`, URL-encode it (or use alphanumeric only)
5. Run `npm run test:db` again

### `Ordering is closed`

The manager ordering window (default 09:30–11:30 IST) is outside current time. Adjust it on the manager dashboard or wait until the window opens.

### Menu images missing after seed

Ensure Cloudinary credentials are correct in `.env` before running `npm run seed`.

---

## License

ISC
