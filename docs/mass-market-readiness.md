# RollTogether Mass-Market Readiness

## Must ship before public beta

1. Real authentication UI: email/password, Sign in with Apple, session persistence, password reset, and verified delete-account flow.
2. Backend-backed discovery: replace seeded local data with Supabase listings, swipes, matches, message threads, messages, blocks, and reports.
3. Realtime chat: subscribe only to authorized `message_threads` and persist every message in Supabase.
4. Push notifications: APNs device token upload to `push_tokens`, notification queue writes to `notifications`, and a server-side sender.
5. Moderation: run profile/listing/message text through a moderation service before public visibility or delivery.
6. Location privacy: geocode locations to coordinates, support distance search, and let users show approximate city instead of exact location.
7. Safety tooling: report review queue, block enforcement across discovery/chat, rate limits, and audit logs for moderation decisions.
8. Production observability: crash reporting, backend error logs, database slow-query monitoring, and funnel analytics.
9. App Store readiness: privacy policy, terms, data deletion procedure, age rating, support URL, screenshots, and TestFlight feedback loop.
10. Abuse prevention: CAPTCHA or device/app attestation on signup, message rate limits, duplicate listing controls, and suspicious behavior throttling.

## Strong next improvements

1. Session Zero questionnaire templates for table rules, content boundaries, scheduling, house rules, and tone.
2. Compatibility badges for play style, schedule overlap, role coverage, campaign tone, and online/in-person fit.
3. Saved searches and alerts for "new group within 25 miles" or "DM looking for 2 players".
4. Verified DM / experienced table host badges after community reputation is established.
5. Calendar availability blocks and time-zone aware scheduling.
6. Rich profile media: avatar, character art, dice pronouns/table pronouns, links to campaign docs where users opt in.
7. Group onboarding checklist: safety tools, consent tools, session cadence, platform, and campaign expectations.
8. Premium later, not now: boosts and advanced filters only after retention proves people find value.

## Recommended service stack

1. Supabase: Auth, Postgres, RLS, Realtime, Storage, Edge Functions.
2. Apple Push Notifications: match and chat notifications.
3. MapKit: autocomplete, geocoding, city/region display, distance filters.
4. OpenAI moderation or equivalent: profile/listing/message safety classification.
5. Sentry: iOS crash reporting and backend error monitoring.
6. RevenueCat: subscriptions only if premium filters/boosts are added.
7. Cloudflare Turnstile or App Attest backed checks: signup/spam abuse mitigation.
