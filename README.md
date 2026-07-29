# QuestBond

QuestBond is a native SwiftUI iOS app for matching D&D groups with solo players and existing parties. The repository is currently named `RollTogether`; QuestBond is the product name shown in the app.

## Project status

The core discovery, matching, chat, profile, and filter experiences are implemented. The primary UX still uses local seed data while authenticated Supabase-backed screens are being completed.

## Highlights

- Browse groups looking for players and parties looking for groups
- Online, in-person, and hybrid session support
- Filters for campaign style, experience, party size, open slots, distance, and text search
- Fit scoring with human-readable match reasons
- Pass, connect, saved match, and private chat flows
- Session Zero prompt chips and match context in conversations
- Editable local profile and first-run onboarding
- Block, report, and local account-deletion actions
- MapKit location autocomplete scaffolding
- APNs registration scaffolding
- Unit tests for matching and filter behavior

## Technology

- SwiftUI
- MapKit
- UserDefaults for current local persistence
- Supabase Auth, Postgres, Realtime, Storage, and Edge Functions
- Native Xcode unit tests

## Repository layout

- [QuestBond.xcodeproj](QuestBond.xcodeproj) — native Xcode project
- [QuestBondApp.swift](QuestBond/QuestBondApp.swift) — application entry point
- [Supabase backend plan](docs/supabase-plan.md)
- [Improvement backlog](docs/improvements.md)
- [Static web prototype](index.html)

## Run locally

Requirements:

- Xcode with an iOS 17 or newer simulator
- macOS capable of running the selected Xcode version

Open [QuestBond.xcodeproj](QuestBond.xcodeproj), select the `QuestBond` scheme, choose an iOS simulator, and run the project.

## Supabase integration

The app connects through `QuestBond/Config/SupabaseConfig.swift` and a lightweight URLSession client in `QuestBond/Services/SupabaseClient.swift`.

Applied migrations:

- `20260514220659_initial_rolltogether_schema` creates profiles, listings, roles, swipes, matches, message threads, messages, reports, blocks, notifications, and push tokens with row-level security enabled.
- `20260514220732_advisor_security_and_index_fixes` revokes public execution on the Supabase-created helper and adds foreign-key indexes flagged by the advisors.

The committed Supabase publishable key is intended for client use. Access control depends on correctly configured row-level security policies; privileged service-role keys must never be embedded in the app.

## Current limitations

- Main screens still use local seed data.
- Push notification delivery is scaffolded but not presented as production-ready.
- External moderation, analytics, payments, and operational monitoring are planning items rather than completed production integrations.
- The repository does not yet include final App Store assets or a public release build.

## Previous prototype

The earlier static prototype remains available for reference:

- [index.html](index.html)
- [app.js](app.js)
- [styles.css](styles.css)
