# RoomieSplit 🏠💸

A modern Fullstack Roommate Expense Management and Split Application built with **Flutter** (frontend), **FastAPI** (backend), and **PostgreSQL** (database).

---

## Key Features

1. **Room & Flat Creation**:
   - Create a room/flat group with custom name and description.
   - Unique room codes for quick identification.

2. **Roommate Invitations with Approval Workflow**:
   - Invite roommates by username or email.
   - Invitee receives an in-app notification with an invitation card on their dashboard.
   - Invitee can **Approve (Accept)** or **Decline (Reject)** the invitation.
   - Only approved/active members are included in room expense calculations and splitting.

3. **Expense Tracking (Kaun, Kya, Kab laya)**:
   - Record what was bought (item title, notes).
   - Price/Amount in ₹.
   - Category tags (Groceries, Vegetables, Food & Dining, Utilities, Rent, Household, Snacks, Other).
   - Date picker to record the exact date the item was bought.
   - Payer selection (who paid).

4. **Flexible & Custom Expense Splitting**:
   - **Default**: Equal split among **all active members** in the room.
   - **Custom Split**: Toggle off the default to select specific roommates who share that particular purchase (e.g. only 2 roommates bought special snacks).
   - Live preview showing `₹Amount ÷ N members = ₹Share each`.

5. **Balances & Debt Calculation Engine**:
   - Total room expenditure tracking.
   - Per-roommate accounting: Total Paid, Total Share, and Net Balance (`+` means you are owed, `-` means you owe).
   - Greedy debt minimization algorithm: Computes simplified *"Who owes whom how much"* settlement paths (e.g. *Rahul owes Amit ₹300*).
   - Built-in **"Settle Up"** action with notes (e.g., UPI, Cash).

---

## Project Structure

```
roomie_split/
├── backend/
│   ├── app/
│   │   ├── core/         # Config & JWT Security
│   │   ├── db/           # PostgreSQL Session & Engine
│   │   ├── models/       # SQLAlchemy models (User, Room, Membership, Expense, Settlement)
│   │   ├── schemas/      # Pydantic v2 schemas
│   │   ├── services/     # Debt calculation & settlement engine
│   │   ├── routers/      # REST API endpoints (/auth, /rooms, /expenses, /balances)
│   │   └── main.py       # FastAPI application
│   └── tests/            # Pytest test suite (100% pass)
├── frontend/
│   ├── lib/
│   │   ├── core/         # Dio API client & constants
│   │   ├── models/       # Data classes (User, Room, Expense, Balance)
│   │   ├── providers/    # State management (Auth, Room, Expense)
│   │   ├── screens/      # Login, Register, Home, RoomDetail, AddExpense
│   │   └── main.dart     # Flutter Material 3 entrypoint
│   └── test/
└── scripts/
    ├── start_postgres.sh # Local PostgreSQL manager (port 5433)
    ├── start_backend.sh  # FastAPI Uvicorn launcher (port 8000)
    └── start_frontend.sh # Flutter launcher (Desktop & Web)
```

---

## How to Run

### Step 1: Create Local Environment File

```bash
cp .env.example .env
```

Set a private JWT secret in `.env`:
```bash
openssl rand -hex 32
```

Keep real credentials only in `.env`. The `.env` files are ignored by git.

### Step 2: Start PostgreSQL & Backend

Run the startup script:
```bash
./scripts/start_backend.sh
```
* Backend API will be live at `http://localhost:8000`
* Interactive Swagger Docs available at `http://localhost:8000/docs`

### Step 3: Run Flutter Frontend

**On Linux Desktop**:
```bash
./scripts/start_frontend.sh
```

**On Web Browser**:
```bash
./scripts/start_frontend.sh web
```
Open `http://localhost:3000` in your web browser.

---

## Automated Verification & Tests

- **Backend Integration Tests**:
  ```bash
  cd backend
  PYTHONPATH=. .venv/bin/pytest tests/
  ```
- **Flutter Static Analysis**:
  ```bash
  cd frontend
  flutter analyze
  ```
