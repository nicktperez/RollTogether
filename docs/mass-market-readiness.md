# RollTogether Mass-Market Readiness

## Implemented in the current production-readiness pass

1. Email/password authentication UI with signup, signin, password reset, Keychain session persistence, sign out, and delete-account flow.
2. Supabase REST client coverage for profiles, listings, listing roles, swipes, matches, message threads, messages, reports, blocks, push tokens, nearby search, and Edge Functions.
3. Supabase-backed app repository wiring for profile save/load, listing publish/load, swipe mirroring, message mirroring, report submission, and block submission.
4. Realtime-ready database setup for `messages`, `message_threads`, `matches`, and `notifications` through the Supabase realtime publication.
5. Notification queue triggers for new messages and matches.
6. `send-push-notifications` Edge Function scaffold for inspecting pending notification work.
7. `delete-account` Edge Function for verified authenticated account deletion through Supabase Auth admin APIs.
8. Local preflight moderation for listings and messages before saving or sending.
9. Location autocomplete plus geocoding into latitude/longitude fields.
10. Coordinate-aware distance filtering in app state and a Supabase `search_listings_nearby` RPC for backend distance search.
11. Account deletion request audit table with RLS and advisor-clean foreign-key indexing.
12. Supabase advisor check: security lints are clean; performance lints only report unused indexes because the project does not have real traffic yet.
13. Server-authoritative match/thread creation through the authenticated `create-match-thread` Edge Function.
14. Native Sign in with Apple entitlement and identity-token exchange plumbing.
15. Realtime chat WebSocket listener tied to chat screens.
16. APNs Edge Function sender with JWT signing and delivery calls, pending Apple secrets.
17. `moderate-content` Edge Function with OpenAI moderation support, pending `OPENAI_API_KEY`.

## Still required before public beta

1. Configure Sign in with Apple in Apple Developer and Supabase. The app entitlement, native identity-token flow, and auth button are now implemented.
2. Add APNs secrets to Supabase Edge Function environment variables and run a device push test. The sender code now signs JWTs and calls APNs.
3. Add `OPENAI_API_KEY` to Supabase for production moderation. The `moderate-content` function falls back to keyword checks until that key exists.
4. Run a two-account device test for server-authoritative match/thread creation and realtime chat delivery. The Edge Function and WebSocket listener are implemented, but real accounts/devices should verify the full flow.
7. Use backend `search_listings_nearby` in discovery queries so distance filtering scales beyond locally loaded listings.
8. Add Storage-backed avatars and listing media with image moderation.
9. Build a moderator/admin review queue for reports, blocked content, and appeal handling.
10. Add rate limits and abuse controls for signup, listing creation, swipes, reports, and messages.
9. Add Sentry or equivalent crash/error monitoring before TestFlight.
10. Create and publish privacy policy, terms of service, support URL, age rating, screenshots, and TestFlight feedback workflow.

## Strong next improvements

1. Session Zero questionnaire templates for table rules, content boundaries, scheduling, house rules, and tone.
2. Compatibility badges for play style, schedule overlap, role coverage, campaign tone, and online/in-person fit.
3. Saved searches and alerts for "new group within 25 miles" or "DM looking for 2 players".
4. Verified DM / experienced table host badges after community reputation is established.
5. Calendar availability blocks and time-zone aware scheduling.
6. Rich profile media: avatar, character art, dice pronouns/table pronouns, and opt-in links to campaign docs.
7. Group onboarding checklist: safety tools, consent tools, session cadence, platform, and campaign expectations.
8. Premium later, not now: boosts and advanced filters only after retention proves people find value.

## Recommended service stack

1. Supabase: Auth, Postgres, RLS, Realtime, Storage, Edge Functions.
2. Apple Push Notifications: match and chat notifications.
3. MapKit/CoreLocation: autocomplete, geocoding, city/region display, distance filters.
4. OpenAI moderation or equivalent: profile/listing/message safety classification.
5. Sentry: iOS crash reporting and backend error monitoring.
6. RevenueCat: subscriptions only if premium filters/boosts are added.
7. Cloudflare Turnstile, App Attest, or DeviceCheck-backed checks: signup/spam abuse mitigation.
