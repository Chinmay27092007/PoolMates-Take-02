# PoolMates — Consolidated Source Files
**Project:** PoolMates (Share the ride. Find your team.)  
**Team:** Code Alchemists · Bennett University  
**Stack:** Flutter Web · Serverpod · PostgreSQL · Dart

All code files created for the full-stack system are collected in this single folder:

### 1. Matching Algorithm & Test Suite
- `matcher.dart` — Pure Dart rule-based matching engine with hard filters (campus, route, ±30 min time window, women-only gating) and skill overlap scoring: `min(100, 40·a + 30·b + 10·c)`.
- `matcher_test.dart` — Complete 5-case test suite covering skill formula, "looking-for" tags, time window, full-ride checks, and women-only security gating.

### 2. Server Endpoints (Serverpod)
- `match_endpoint.dart` — RPC endpoint that queries PostgreSQL and returns ranked matches sorted by skill synergy score.
- `ride_endpoint.dart` — Ride CRUD, join/leave, server-side women-only enforcement, cancellation, and live cost split broadcast.
- `profile_endpoint.dart` — Campus email domain verification (`bennett.edu.in`) and profile management.
- `chat_endpoint.dart` — Streaming live chat per ride.
- `channel_endpoint.dart` — Streaming community channels (`#general`, `#airport-runs`, `#hackathons`, `#clubs`).
- `share_endpoint.dart` — Unauthenticated public trip inspection by token (`/trip/:token`) for parents.
- `seed_endpoint.dart` — Database seeder populating Bennett University, community rooms, and 20+ demo users/rides.

### 3. Data Models (`.spy.yaml`)
- `campus.spy.yaml` — Campus domain allow-list table.
- `user_profile.spy.yaml` — Student profile table (skills, interests, lookingFor tags).
- `ride.spy.yaml` — Cab ride offers/requests table.
- `ride_member.spy.yaml` — Ride participants table.
- `ride_message.spy.yaml` — Per-ride chat messages table.
- `channel.spy.yaml` — Community channels table.
- `channel_message.spy.yaml` — Community messages table.
- `matched_ride.spy.yaml` — Ranked match response object.
- `public_trip_summary.spy.yaml` — Safety preview model.

### 4. Frontend & Web Application
- `index.html` — Standalone full-featured single-page web app running live on http://localhost:8082 with all 11 screens.
- `app_theme.dart` — Pitch deck visual tokens (Navy `#12263A`, Cream `#F6F4EE`, Orange `#F4A261`, Teal `#1F7A6F`, Merriweather typography).
- `dashed_route_painter.dart` — Animated custom painter for the Campus → Airport dashed curve route motif.


## Run locally (Windows)
Double-click `START_POOLMATES.bat`. It serves this folder at http://localhost:8085 and opens the page.
The site now starts **signed out**; Find Matches, Post a Ride, Channels, Profile, joining rides and chat all ask the
student to sign in first (name, @bennett.edu.in email, optional photo, course, branch, year, interests, date of birth, home state).
