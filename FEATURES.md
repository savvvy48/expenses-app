# Daily Expenses — Feature List

## 🏠 Home Screen
- Time-aware greeting (Good Morning / Afternoon / Evening)
- **Wallet Balance Hero Card** — Large animated balance with eye-toggle for privacy
- Income & Expense summary pills
- **Quick Actions** — Add, Analytics, Budget, More (circular icon buttons)
- Budget warning indicator (appears when nearing/exceeding limit)
- **Date-grouped transaction list** — Today / Yesterday / Date headers
- Each transaction shows: category icon, title, category label, amount (+/-), and time

## ➕ Add Transaction Screen
- **Income / Expense toggle** — Pill-style selector
- **Custom keypad** — On-screen number pad with decimal support and backspace
- **Category selector** — Bottom sheet with default + custom categories
- **Payment method selector** — Cash, Card, UPI, Bank Transfer, Wallet
- **Currency selector** — USD, INR, EUR, GBP, JPY, AED, CAD with live symbol preview
- **Date picker** — Calendar-based date selection
- **Title input** — Free-text transaction description
- **Notes** — Optional description/memo field
- **Receipt attachment** — Camera or gallery image picker with UUID-prefixed filenames
- **Recurring transactions** — Daily, Weekly, Monthly, Yearly auto-generation
- **Expense splitting** — Split with contacts, per-person amount, paid/unpaid status
- **Templates** — Save as template / load from saved templates
- **Budget warning** — Alert before saving if daily limit would be exceeded
- **Success overlay** — Animated confirmation after saving

## 📊 Analytics Screen
- **Gradient hero header** — Violet gradient card with animated total counter
- Income vs Spent stat chips
- **Period selector** — Week / Month / Year full-width pill toggle
- **Weekly spending trend** — Bar chart with gradient-filled bars, highest bar highlighted
- **Interactive donut chart** — Touch to expand sections, centered total display, color legend
- **Category breakdown** — Animated progress bars per category with icon, name, percentage, and amount

## 👥 People Screen
- **Contact list** — Avatar (initials), name, email, chevron indicator
- **Add Person** — Frosted glass bottom sheet with name, email, phone fields
- First-run sample data seeding (Alice & Bob)
- Active members and pending invites filtering

## ⚙️ Settings Screen
- **Dark Mode toggle** — System-aware with smooth animated transition
- **Currency picker** — Frosted glass bottom sheet with 7 currencies, live checkmark indicator
- **Manage Categories** — Add/edit/delete custom expense categories
- **Monthly Budget** — Set monthly and daily spending limits
- **Export Data** — CSV export with share sheet (date, title, amount, category, payment method, notes)
- **Clear All Data** — Confirmation bottom sheet with destructive action warning

## 💰 Budget Screen
- Monthly budget limit slider/input
- Daily budget limit slider/input
- Per-category budget limits
- 5-tier status system: Safe → Notice → Warning → Critical → Exceeded
- Color-coded utilization indicators

## 📋 Templates Screen
- List of saved transaction templates
- One-tap to load a template into Add Transaction screen
- Template cards with category icon, title, and amount

## 🌊 Splash Screen
- Shimmer loading skeleton matching Home Screen layout
- Async provider initialization with safety timeout
- Minimum display time to prevent flicker

## 🧭 App Shell (Navigation)
- **Floating bottom nav bar** — Rounded, icon-only with dot indicator on active tab
- **Violet glow center FAB** — Gradient + glow shadow, spring animation on press
- Home / Analytics / [+] / People / Settings
- Slide + fade page transitions with directional awareness
- Slide-up transition for Add Transaction

---

## 🔧 Under the Hood

### Data & Storage
- **Hive** local database — Expenses, people, settings, budgets in separate boxes
- Schema migration helper with version checking
- Undo support for delete operations (`undoDelete`)
- Batch delete with `Future.wait` for efficiency

### State Management
- **Provider** pattern — `ExpenseProvider`, `SettingsProvider`, `PeopleProvider`, `BudgetProvider`
- Sort options: Date ↑↓, Amount ↑↓, Category A-Z
- Filter by: search query, category, payment method, date range

### Design System
- True-black dark theme (`#0D0D0D`) + warm neutral light theme
- Violet primary accent (`#8B5CF6`)
- 24px border-radius cards with 1px borders (no shadows)
- **Inter** font via Google Fonts throughout
- `SpringButton` for haptic micro-interactions
- Frosted glass (`BackdropFilter`) bottom sheets
- `AnimatedListItem` for staggered list entrance animations

### Models
- **Expense** — id, title, amount, category, date, notes, paymentMethod, currency, isRecurring, recurringType, receiptPaths, splits, isIncome, createdAt, isTemplate
- **ExpenseCategory** — id, label, icon, color, isCustom (7 defaults + user-created)
- **ExpenseSplit** — personId, personName, amount, isPaid
- **Person** — id, name, email, phone, status, avatarColor
- **Budget** — id, monthlyLimit, dailyLimit, categoryLimits
- **TimePeriod** — Day, Week, Month, Year
