# QuestBond

QuestBond is a native SwiftUI iOS app for matching DND groups with singles, duos, trios, and larger player parties.

## Current App

- Native iOS project: [QuestBond.xcodeproj](/Users/nickperez/DND%20App/QuestBond.xcodeproj)
- App source: [QuestBondApp.swift](/Users/nickperez/DND%20App/QuestBond/QuestBondApp.swift)
- Bundle ID: `com.nickperez.questbond`
- Minimum iOS target: `17.0`

## Features

- Browse groups looking for players.
- Browse player parties looking for groups.
- Pre-search and post-search filters for session type, campaign style, table experience, party size, open slots, and text search.
- Online, in-person, and hybrid session support.
- Fit scoring with match reasons.
- Pass and connect actions.
- Saved connections that open private chat threads.
- Chat inbox with match context, message composer, and Session Zero prompt chips.
- Editable local profile.
- First-run onboarding that explains discovery, new searches, and chat.
- Main navigation focused on `Discover`, `Chats`, and `More`.
- Floating plus action on Discover for starting a new group/player search setup.
- Local delete-account action in `More`.
- Native forms for group and party listings.
- Local persistence using `UserDefaults`.
- Generated brand mark/theme asset in the Xcode asset catalog.

## Backend Planning

- [Supabase backend plan](</Users/nickperez/DND App/docs/supabase-plan.md>)
- [Improvement backlog](</Users/nickperez/DND App/docs/improvements.md>)

Firebase is not required for the current direction. Supabase covers the main needs for this app: Auth, Postgres data, private Realtime chat, Storage, and Edge Functions. Firebase would mainly be an alternative stack, not an additional requirement.

## Screenshot Checklist Coverage

The app now includes an in-app `More > Services & Data Model` checklist for:

- Apple Push Notifications
- MapKit / location autocomplete
- OpenAI moderation
- Sentry
- RevenueCat
- Cloudflare Turnstile
- users
- profiles
- listings
- listing_roles
- swipes
- matches
- messages
- message_threads
- reports
- blocks
- notifications

## Run

Open [QuestBond.xcodeproj](/Users/nickperez/DND%20App/QuestBond.xcodeproj) in Xcode, select the `QuestBond` scheme, and run on an iOS simulator.

The previous static web prototype files are still present for reference:

- [index.html](/Users/nickperez/DND%20App/index.html)
- [app.js](/Users/nickperez/DND%20App/app.js)
- [styles.css](/Users/nickperez/DND%20App/styles.css)
