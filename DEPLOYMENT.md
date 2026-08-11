# SSM SkipQ — Deployment Guide

Step-by-step instructions to deploy the app to production using **Render** (backend API) and **Vercel** (frontend PWA). These match the stack documented in this repository.

**Architecture**

```
Student/Manager browser
        ↓
  Vercel (frontend)          Render (backend API + Socket.io)
  ssm-skipq-frontend    →    ssm-skipq-backend
                                    ↓
                             MongoDB Atlas + Cloudinary
```

---

## Before you start

You will need accounts on:

| Service | Purpose |
|---------|---------|
| [GitHub](https://github.com) | Source code (repo must be pushed) |
| [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) | Database |
| [Cloudinary](https://cloudinary.com) | Menu image storage |
| [Render](https://render.com) | Backend hosting |
| [Vercel](https://vercel.com) | Frontend hosting |

**Repo structure** — this is a monorepo:

```
skipQ/
├── ssm-skipq-backend/    ← deploy to Render
└── ssm-skipq-frontend/   ← deploy to Vercel
```

Push your latest code to GitHub before deploying:

```bash
git push origin main
```

---

## Part 1 — MongoDB Atlas

### 1. Create a cluster

1. Log in to [MongoDB Atlas](https://cloud.mongodb.com).
2. Create a **free M0 cluster** (fine for pilot/demo use).
3. Choose a cloud region close to your users (e.g. Mumbai / AWS ap-south-1).

### 2. Create a database user

1. Go to **Database Access** → **Add New Database User**.
2. Choose **Password** authentication.
3. Save the username and password — you will need them for `MONGODB_URI`.

### 3. Allow network access

1. Go to **Network Access** → **Add IP Address**.
2. For cloud deployment, add **`0.0.0.0/0`** (allow from anywhere).
   - Required because Render’s server IP is not fixed on the free tier.
   - Tighten this later with a paid static IP if needed.

### 4. Get the connection string

1. Go to **Database** → **Connect** → **Drivers**.
2. Copy the connection string, e.g.:
   ```
   mongodb+srv://<username>:<password>@cluster.mongodb.net/ssm-skipq?retryWrites=true&w=majority
   ```
3. Replace `<username>` and `<password>` with your real credentials.
4. If the password contains special characters (`@`, `#`, `/`, `:`, `?`), [URL-encode](https://www.urlencoder.org/) them.

### 5. Test locally (optional)

From your machine, in `ssm-skipq-backend`:

```bash
# Set MONGODB_URI in .env, then:
npm run test:db
```

---

## Part 2 — Cloudinary

### 1. Create an account

1. Sign up at [cloudinary.com](https://cloudinary.com).
2. Open the **Dashboard**.

### 2. Copy credentials

Note these three values for the backend environment:

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

Menu images uploaded by managers are stored under the `ssm-skipq/menu` folder in Cloudinary.

---

## Part 3 — Deploy the backend (Render)

### 1. Create a Web Service

1. Log in to [Render](https://dashboard.render.com).
2. Click **New +** → **Web Service**.
3. Connect your GitHub account and select the **SsmskipQ** repository.

### 2. Configure the service

| Setting | Value |
|---------|-------|
| **Name** | `ssm-skipq-api` (or any name you prefer) |
| **Region** | Same region as MongoDB if possible |
| **Branch** | `main` |
| **Root Directory** | `ssm-skipq-backend` |
| **Runtime** | Node |
| **Build Command** | `npm install` |
| **Start Command** | `npm start` |
| **Instance type** | Free (for testing) |

### 3. Set environment variables

In Render → your service → **Environment**, add:

| Variable | Example / notes |
|----------|-----------------|
| `NODE_ENV` | `production` |
| `MONGODB_URI` | Your Atlas connection string |
| `JWT_SECRET` | Long random string (generate one; do not reuse dev secrets) |
| `JWT_EXPIRES_IN` | `30d` |
| `CLIENT_URL` | Your Vercel URL — see below |
| `CLOUDINARY_CLOUD_NAME` | From Cloudinary dashboard |
| `CLOUDINARY_API_KEY` | From Cloudinary dashboard |
| `CLOUDINARY_API_SECRET` | From Cloudinary dashboard |

**`CLIENT_URL`** — comma-separated list of frontend origins allowed for CORS and Socket.io:

```
https://your-app.vercel.app,http://localhost:5173
```

- Use your **exact** Vercel URL (no trailing slash).
- Include `http://localhost:5173` if you still develop locally against the live API.
- You can add the URL after deploying the frontend, then redeploy the backend.

> **Note:** Render sets `PORT` automatically — do not override it.

### 4. Deploy

1. Click **Create Web Service**.
2. Wait for the build to finish.
3. Copy your live API URL, e.g. `https://ssm-skipq-api.onrender.com`.

### 5. Verify the backend

Open in a browser or run:

```bash
curl https://YOUR-RENDER-URL.onrender.com/api/health
```

Expected response:

```json
{
  "success": true,
  "message": "SSM SkipQ API is running",
  "db": "connected"
}
```

If `"db": "disconnected"`, check `MONGODB_URI` and Atlas network access.

### 6. Seed production data (first time)

Run these **once** from your local machine with production `MONGODB_URI` in `.env`:

```bash
cd ssm-skipq-backend
npm run seed          # 9 categories + 26 menu items
npm run seed:manager  # default manager SSM001 / manager123
```

Alternatively, use Render’s **Shell** tab (if available on your plan) with the same commands.

**Change the default manager password** before going live with real users.

---

## Part 4 — Deploy the frontend (Vercel)

### 1. Import the project

1. Log in to [Vercel](https://vercel.com).
2. Click **Add New…** → **Project**.
3. Import the same GitHub repository.

### 2. Configure the project

| Setting | Value |
|---------|-------|
| **Framework Preset** | Vite |
| **Root Directory** | `ssm-skipq-frontend` |
| **Build Command** | `npm run build` |
| **Output Directory** | `dist` |
| **Install Command** | `npm install` |

### 3. Set environment variables

Add this in Vercel → **Settings** → **Environment Variables**:

| Variable | Value |
|----------|-------|
| `VITE_API_URL` | `https://YOUR-RENDER-URL.onrender.com/api` |

**Important:**

- Must be the full HTTPS URL.
- Must end with `/api` (the app also auto-appends `/api` if omitted, but setting it explicitly avoids mistakes).
- No trailing slash after `/api`.

Example:

```
VITE_API_URL=https://ssm-skipq-api.onrender.com/api
```

### 4. Deploy

1. Click **Deploy**.
2. Wait for the build to complete.
3. Copy your live frontend URL, e.g. `https://ssm-skipq.vercel.app`.

### 5. Update backend CORS

Go back to **Render** → backend service → **Environment**:

1. Set or update `CLIENT_URL`:
   ```
   https://ssm-skipq.vercel.app,http://localhost:5173
   ```
2. Save — Render will redeploy automatically.

---

## Part 5 — Post-deployment checklist

Run through this list after both services are live:

- [ ] **Health check** — `https://YOUR-API.onrender.com/api/health` returns `"db": "connected"`
- [ ] **Student register/login** — open the Vercel URL, register a test student
- [ ] **Manager login** — use `SSM001` / `manager123` (or your seeded credentials)
- [ ] **Menu loads** — home page shows categories and items
- [ ] **Place a test order** — checkout completes and shows a token (A001, etc.)
- [ ] **Real-time updates** — manager sees the order without refreshing; student timeline updates when manager advances status
- [ ] **Menu upload** — manager can add/edit an item with a photo (Cloudinary working)
- [ ] **PWA install** — on mobile Chrome, “Add to Home Screen” works
- [ ] **Ordering window** — manager can set open/close times on the dashboard

---

## Part 6 — Install as PWA on phones

1. Open the **Vercel URL** in Chrome (Android) or Safari (iOS).
2. **Android:** Menu → **Install app** or **Add to Home screen**.
3. **iOS:** Share → **Add to Home Screen**.

The app name shown is **SkipQ** (manifest: `SkipQ@SSM`).

---

## Troubleshooting

### CORS error in browser console

**Cause:** Frontend origin not listed in backend `CLIENT_URL`.

**Fix:**

1. Render → Environment → set `CLIENT_URL` to your exact Vercel URL (no trailing slash).
2. Redeploy the backend.

### `Network Error` / API requests fail

**Cause:** Wrong `VITE_API_URL` or backend is sleeping (Render free tier).

**Fix:**

1. Confirm `VITE_API_URL` is `https://YOUR-API.onrender.com/api`.
2. Open the health URL in a browser to wake the server, then retry.
3. Redeploy Vercel after changing env vars (Vite bakes env at build time).

### Socket.io / live updates not working

**Cause:** CORS origin mismatch or backend not reachable.

**Fix:**

1. Ensure `CLIENT_URL` includes the Vercel URL.
2. Confirm the API health endpoint works over HTTPS.
3. Check browser DevTools → Network → WS tab for WebSocket errors.

### `bad auth : authentication failed` (MongoDB)

**Cause:** Wrong username/password in `MONGODB_URI`.

**Fix:**

1. Reset password in Atlas → Database Access.
2. Update `MONGODB_URI` on Render.
3. URL-encode special characters in the password.

### Render service spins down (free tier)

Render free web services **sleep after ~15 minutes** of inactivity. The first request after sleep may take 30–60 seconds. This is normal for testing; upgrade to a paid instance for always-on production use.

### Menu images missing

**Cause:** Cloudinary credentials wrong or seed ran without Cloudinary configured.

**Fix:**

1. Verify all three `CLOUDINARY_*` vars on Render.
2. Re-run `npm run seed` locally against production DB, or upload images via the manager menu UI.

### Student sees “Ordering is closed”

**Cause:** Current IST time is outside the manager ordering window (default 09:30–11:30).

**Fix:** Manager → Dashboard → adjust **Ordering Window** → Save.

### Changes to `VITE_API_URL` not applied

Vite environment variables are embedded at **build time**. After changing `VITE_API_URL` on Vercel, trigger a **new deployment** (Redeploy from the Vercel dashboard).

---

## Environment variable reference

### Backend (`ssm-skipq-backend`)

| Variable | Required | Description |
|----------|----------|-------------|
| `PORT` | Auto (Render) | Server port |
| `NODE_ENV` | Yes | Set to `production` on Render |
| `MONGODB_URI` | Yes | MongoDB Atlas connection string |
| `CLIENT_URL` | Yes | Comma-separated frontend URLs for CORS/Socket.io |
| `JWT_SECRET` | Yes | Secret for signing auth tokens |
| `JWT_EXPIRES_IN` | Optional | Token lifetime (default `30d`) |
| `CLOUDINARY_CLOUD_NAME` | Yes | Cloudinary cloud name |
| `CLOUDINARY_API_KEY` | Yes | Cloudinary API key |
| `CLOUDINARY_API_SECRET` | Yes | Cloudinary API secret |

### Frontend (`ssm-skipq-frontend`)

| Variable | Required | Description |
|----------|----------|-------------|
| `VITE_API_URL` | Yes | Backend URL including `/api`, e.g. `https://api.example.com/api` |

---

## Optional — custom domain

### Vercel (frontend)

1. Vercel → Project → **Settings** → **Domains**.
2. Add your domain (e.g. `skipq.ssmiet.edu.in`).
3. Follow DNS instructions from Vercel.

### Render (backend)

1. Render → Service → **Settings** → **Custom Domains**.
2. Add e.g. `api.skipq.ssmiet.edu.in`.
3. Update DNS as instructed.

After adding custom domains:

1. Update `VITE_API_URL` on Vercel to the new API domain.
2. Update `CLIENT_URL` on Render to the new frontend domain.
3. Redeploy both services.

---

## Security reminders before go-live

- Rotate `JWT_SECRET` and MongoDB password — do not use development values in production.
- Change the default manager password (`manager123`) immediately after seeding.
- Never commit `.env` files or secrets to GitHub.
- Consider upgrading MongoDB Atlas from M0 before full campus rollout (see `PROJECT_OVERVIEW.md` roadmap).

---

*For local development setup, see [README.md](./README.md). For stakeholder overview, see [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md).*
