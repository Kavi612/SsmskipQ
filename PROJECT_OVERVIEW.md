# SSM SkipQ — Project Overview

**Pre-Order · Pick Up · Enjoy**

A stakeholder summary of the SSM SkipQ canteen pre-ordering application, based on the current implementation in this repository.

---

## 1. PROJECT SUMMARY

SSM SkipQ is a mobile-friendly web application that lets students at SSM Institute of Engineering and Technology pre-order food from the campus canteen, pay online (simulated) or at the counter, receive a daily pickup token, and track their order until collection. Canteen staff use a separate Manager Portal to receive orders in real time, advance order status, manage the menu, control when ordering is open, and review student feedback.

The app is built as a Progressive Web App (PWA), so students and staff can add it to their phone home screen without installing from an app store.

---

## 2. USER WORKFLOW

### Student journey

1. **Open the app** — The student lands on a branded splash screen (`/`). Tapping the screen slides up to the welcome/login screen.
2. **Register or log in** — On the welcome screen, the student chooses **Register** (full name + 10-digit mobile number) or **Login** (mobile number only; no password). Valid mobile numbers must be 10 digits starting with 6, 7, 8, or 9. Staff can reach the manager login via **Canteen Staff Login** at the bottom of this screen, or directly at `/manager/login`.
3. **Browse the menu** — After login, the student is taken to the home screen (`/student`). They see a personalized greeting, category tabs (e.g. Rice Varieties, Parotta, Fried Rice), search, and veg/non-veg filters. Each item shows price, veg/non-veg indicator, and image where available. If ordering is outside the configured window, a banner appears and items show as **Closed** instead of allowing add-to-cart.
4. **Build a cart** — The student adds items from the menu and opens the cart (`/student/cart`) from the bottom navigation. They can increase/decrease quantities or remove items. A badge on the Cart tab shows the total item count.
5. **Checkout** — From the cart, the student proceeds to checkout (`/student/checkout`), reviews the order summary and bill (subtotal + packaging charge, currently ₹0), and selects a payment method:
   - **Pay Online (Mock)** — Simulates online payment with a short processing delay; the order is marked as paid immediately.
   - **Pay at Counter** — Payment is deferred until pickup; the order stays pending until staff confirm receipt.
6. **Receive token and track** — After placing the order, the student sees an order confirmation screen (`/student/order-confirmation`) with their **daily token number** (format A001, A002, …, resetting each day in IST), payment method, item list, and a live **Order Status** timeline (Order Received → Preparing → Ready for Pickup → Collected). Status updates appear automatically without refreshing.
7. **View order history** — All orders are listed on the Orders screen (`/student/orders`), with status badges, payment details, and timestamps in Indian Standard Time.
8. **Reorder** — From a past order, the student can tap **Reorder** to add available items back to the cart (unavailable items are skipped with a notice).
9. **Submit feedback** — After an order is marked **Collected**, the student can rate it 1–5 stars and optionally leave a short written review directly on the Orders screen.
10. **Profile and logout** — The Profile screen (`/student/profile`) shows the student’s name and mobile number, with a logout option.

### Manager journey

1. **Log in** — Staff open `/manager/login` and sign in with a **Manager ID** and **password** (default test account: `SSM001` / `manager123`, created by the seed script).
2. **Dashboard overview** — The manager lands on the Dashboard (`/manager`), which shows today’s stats: total orders, pending orders, ready orders, and today’s revenue. A **Recent Orders** feed lists the latest incoming orders with token, student name, status, and payment state.
3. **Set the ordering window** — On the same Dashboard, staff configure **Open** and **Close** times (24-hour format, IST). The default window is 09:30–11:30 IST. Saving updates whether students can place new orders. Students outside this window see ordering as closed.
4. **Manage live orders** — On the Orders screen (`/manager/orders`), staff see all of today’s orders update in real time. For each active order they can:
   - **Accept** (Pending → Confirmed)
   - **Preparing** (Confirmed → Preparing)
   - **Ready** (Preparing → Ready)
   - **Collected** (Ready → Picked Up)
   - **Mark Payment Received** for pay-at-counter orders
   - **Call Student** via phone link, or view the mobile number in a popup
   New orders trigger an in-app notification and an alert sound.
5. **Manage the menu** — On the Menu screen (`/manager/menu`), staff can add new items (name, description, price, category, veg/non-veg, photo), edit existing items, update prices, mark items as available or sold out, and delete items. Photos are stored via Cloudinary.
6. **View feedback** — On the Feedback screen (`/manager/feedback`), staff see student star ratings and written reviews linked to order tokens, with student name and order details.
7. **Profile and logout** — The Profile screen (`/manager/profile`) shows the manager’s name and ID, with a logout option.

Navigation is available via a side/top bar on larger screens and a bottom bar on mobile (Dashboard, Orders, Menu, Feedback, Profile).

---

## 3. FEATURES LIST

### Student Features

- Branded splash screen with animated transition to login
- Register with name + mobile, or login with mobile only (no password)
- Browse menu by category with search and veg/non-veg filter
- View item images, prices, descriptions, and veg/non-veg indicators
- Ordering-window awareness — blocked ordering when canteen is closed
- Shopping cart with quantity controls and item count badge
- Checkout with order summary and bill breakdown
- Mock online payment or pay-at-counter option
- Daily pickup token numbers (A001, A002, … per day)
- Live order status timeline on confirmation screen
- Order history with status badges and IST timestamps
- One-tap **Reorder** from past orders
- Post-collection feedback (1–5 star rating + optional review)
- Profile page with name and mobile
- Bottom navigation: Home, Cart, Orders, Profile

### Manager Features

- Secure login with Manager ID and password
- Dashboard with today’s order counts, ready count, and revenue
- Configurable ordering window (open/close times in IST)
- Live recent-orders feed on the dashboard
- Full orders list with real-time updates
- Order status workflow: Accept → Preparing → Ready → Collected
- Mark payment received for pay-at-counter orders
- Call student (phone link + number display)
- Menu management: add, edit, delete items
- Inline price updates and availability toggle (sold out)
- Menu item photo upload
- Feedback dashboard with star ratings and reviews
- Profile page with manager name and ID
- Navigation: Dashboard, Orders, Menu, Feedback, Profile

### Real-time Features

- Instant notification to managers when a new order is placed
- Alert sound on new orders for managers
- Live order status updates for both students and managers (no page refresh)
- In-app toast notifications for students when order status changes
- Live broadcast when the ordering window is updated
- Dashboard and orders list refresh automatically via WebSocket connection

### Technical Features

- **JWT authentication** — Secure session tokens for students and managers (stored in browser; validated on API and WebSocket connections)
- **Role-based access** — Separate student and manager routes and permissions
- **MongoDB database** — Stores students, managers, menu, orders, feedback, and settings
- **Cloudinary image hosting** — Menu photos uploaded and served from the cloud
- **Multer file upload** — Handles image uploads from the manager menu form
- **Socket.io** — Real-time order and settings events
- **Progressive Web App (PWA)** — Installable on mobile; offline-capable shell with auto-update
- **CORS configuration** — Allows the frontend origin to communicate with the API
- **Health check endpoints** — API status available at `/` and `/api/health`
- **IST time handling** — Ordering window, tokens, and timestamps use Indian Standard Time
- **Responsive layout** — Mobile-first design with dedicated bottom navigation on phones
- **Framer Motion animations** — Splash, checkout, and UI transitions
- **CSS Modules** — Scoped component styling throughout the frontend
- **TypeScript frontend** — Type-safe React application
- **Seed scripts** — One-command setup for demo menu (9 categories, 26 items) and default manager account

---

## 4. TECH STACK

Technologies taken from the project’s `package.json` files and codebase:

| Technology | Role |
|---|---|
| **React 19** | Builds the interactive student and manager user interfaces |
| **Vite 7** | Frontend development server and production build tool |
| **TypeScript** | Adds type safety to the frontend codebase |
| **React Router 7** | Handles page routing (splash, student screens, manager portal) |
| **CSS Modules** | Component-scoped styling for all pages and UI elements |
| **Framer Motion** | Animations on splash, checkout, and cart interactions |
| **lucide-react** | Icon set used across navigation, cards, and actions |
| **Axios** | HTTP client for all frontend-to-backend API calls |
| **Socket.io Client** | Receives live order and settings updates in the browser |
| **vite-plugin-pwa** | Generates PWA manifest, service worker, and installable app icons |
| **Node.js (≥ 20)** | Runtime for the backend API server |
| **Express 5** | REST API framework serving auth, menu, order, and settings endpoints |
| **Mongoose 8** | MongoDB object modeling and database queries |
| **MongoDB Atlas** | Cloud-hosted document database (currently free M0 tier) |
| **Socket.io (server)** | Pushes real-time order and settings events to connected clients |
| **JSON Web Token (jsonwebtoken)** | Issues and verifies authentication tokens |
| **bcryptjs** | Hashes manager passwords before storage |
| **Cloudinary** | Stores and delivers menu item images |
| **Multer** | Parses multipart form data for image uploads |
| **CORS** | Controls which frontend origins may access the API |
| **dotenv** | Loads environment variables for local and deployed configuration |
| **Nodemon** | Auto-restarts the backend during local development |
| **ESLint & Prettier** | Code linting and formatting for the frontend |

---

## 5. HOW TO RUN THE PROJECT

These steps assume a fresh clone on a machine with **Node.js 20 or later** installed.

### Step 1 — Clone the repository

```bash
git clone https://github.com/Kavi612/SsmskipQ.git
cd SsmskipQ
```

### Step 2 — Set up the backend

```bash
cd ssm-skipq-backend
npm install
```

Copy the example environment file and fill in your own values:

```bash
cp .env.example .env
```

On Windows (PowerShell):

```powershell
copy .env.example .env
```

**Required backend environment variables** (names only — use your own values, never commit secrets):

- `PORT`
- `NODE_ENV`
- `MONGODB_URI`
- `CLIENT_URL`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

Test the database connection:

```bash
npm run test:db
```

Seed the database (first time only):

```bash
npm run seed          # Creates 9 menu categories and 26 sample menu items
npm run seed:manager  # Creates the default manager account (SSM001)
```

Start the API server:

```bash
npm run dev
```

The backend runs at **http://localhost:5000**.

### Step 3 — Set up the frontend

Open a second terminal:

```bash
cd ssm-skipq-frontend
npm install
```

Copy the example environment file:

```bash
cp .env.example .env
```

**Required frontend environment variable:**

- `VITE_API_URL` — Must point to the backend API base URL including `/api` (e.g. `http://localhost:5000/api` for local development)

Start the frontend:

```bash
npm run dev
```

The app opens at **http://localhost:5173**.

### Step 4 — Use the app

| Role | How to sign in |
|---|---|
| **Student** | Register with name + mobile, or log in with mobile only |
| **Manager** | Manager ID `SSM001`, password `manager123` (after running `npm run seed:manager`) |

Both the backend and frontend must be running at the same time for the app to work.

---

## 6. HOW TO MANAGE THE APP (for non-technical stakeholders)

This section is for canteen staff who will use the Manager Portal day to day — no technical knowledge required.

### Starting your shift

1. Open the app in your phone or tablet browser (or use the installed PWA shortcut).
2. Tap **Canteen Staff Login** and sign in with your Manager ID and password.
3. You will land on the **Dashboard**, which shows how many orders have come in today.

### Setting when students can order

Before service begins, check the **Ordering Window** section on the Dashboard:

- Set the **Open** time (when pre-orders start) and **Close** time (when pre-orders stop).
- Tap **Save**.
- The status will show **Open** or **Closed** depending on the current time.

Students cannot place new orders outside this window. Adjust the times each day as needed (for example, if the canteen opens earlier on exam days).

### Handling incoming orders

1. Go to **Orders** from the navigation bar.
2. New orders appear automatically — you will hear a notification sound and see a popup with the token number and amount.
3. Each order card shows:
   - **Token number** (e.g. A003) — call this out when the student arrives
   - **Items ordered** and total amount
   - **Student name and mobile number**
   - **Payment method** (Paid Online or Pay at Counter)

4. Advance each order through the kitchen workflow using the action buttons:
   - **Accept** — acknowledge the order
   - **Preparing** — kitchen is working on it
   - **Ready** — order is ready for pickup
   - **Collected** — student has picked up the food

5. For **Pay at Counter** orders, tap **Mark Payment Received** once the student pays at the counter.

6. If you need to reach the student, tap **Call Student** or the **#** button to see their mobile number.

### Managing the menu

Go to **Menu** to:

- **Add a new item** — fill in name, price, category, veg/non-veg, optional description, and a photo, then save.
- **Edit an item** — tap the edit icon to change details or replace the photo.
- **Change a price** — edit the price field directly; it saves when you leave the field.
- **Mark sold out** — toggle availability so students cannot order an item that is finished for the day.
- **Remove an item** — delete items that are no longer on the menu.

Changes take effect immediately for students browsing the menu.

### Reading feedback

Go to **Feedback** to see star ratings and written reviews from students after they collect their orders. Each entry shows the order token, rating, review text, student name, and what they ordered. Use this to identify popular items and areas for improvement.

### Ending your shift

Tap **Profile** and then **Logout** when finished. No special shutdown steps are needed — the system keeps running on the server.

---

## 7. CURRENT DEPLOYMENT STATUS

The application is **primarily developed and run locally** for testing and pilot use. The repository on GitHub (`https://github.com/Kavi612/SsmskipQ`) contains the full source code but **does not include a pinned production URL or active deployment configuration file** (no hosted frontend or backend URL is defined in the codebase).

The project README documents optional deployment to **Render** (backend API) and **Vercel** (frontend) using free-tier hosting, with **MongoDB Atlas M0** (free cluster) for the database and **Cloudinary** (free tier) for menu images. These services are suitable for demonstration, pilot testing, and small-scale use — not yet configured for full daily campus traffic at production scale.

To go live for the institute, the frontend and backend would need to be deployed to hosting services, environment variables configured on each platform, and the backend `CLIENT_URL` updated to allow the deployed frontend address.

---

## 8. ROADMAP — PLANNED UPGRADES

The items below are **planned future enhancements** and are **NOT YET IMPLEMENTED** in the current version of SSM SkipQ.

### a) Manager OTP Authentication

Add one-time password (OTP) verification — via SMS through a provider such as Twilio or MSG91 — as a second step after the existing Manager ID + Password login. This would prevent unauthorized access to order and menu management even if a password is shared or compromised.

**Requirements:** A paid SMS gateway account, registration with the provider, and changes to the manager login flow in both the backend and frontend.

### b) Razorpay Payment Integration

Replace the current mock online payment (simulated “Pay Online” with no real money transfer) and limited pay-at-counter flow with **real Razorpay integration** for actual online payments. This would cover creating a payment order through Razorpay’s API, verifying payment via webhook or signature check, and updating each order’s payment status only after confirmed payment.

**Requirements:** A registered Razorpay business account, completion of KYC verification, and backend/frontend changes to the checkout and order creation flow. Until this is live, online payments in the app are for demonstration only.

### c) Production Database Scaling

Move from the current **MongoDB Atlas M0 free-tier cluster** to a paid tier (M2 or higher) to handle concurrent multi-user load reliably during peak canteen hours. This upgrade would also enable automated backups and appropriate connection pool limits in the database layer for production traffic.

**Note:** The free tier is adequate for pilot, demo, and low-traffic testing, but is not recommended for full-scale daily use across the entire campus.

---

*Document generated from the SSM SkipQ codebase. Last updated: July 2026.*
