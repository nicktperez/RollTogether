# Supabase Backend Plan

QuestBond now uses Supabase as the primary production backend for account identity, social data, messaging persistence, notification queues, and safety records.

## Connected Project

- Project name: `RollTogether`
- Project ref: `mczhglpdsoiipdqsbjsl`
- iOS config: `QuestBond/Config/SupabaseConfig.swift`
- Client implementation: `QuestBond/Services/SupabaseClient.swift`

## Applied Migrations

1. `20260514220659_initial_rolltogether_schema`: creates the initial profiles, listings, listing roles, swipes, matches, message threads, messages, reports, blocks, notifications, and push tokens tables with RLS enabled.
2. `20260514220732_advisor_security_and_index_fixes`: revokes public execution on the generated RLS helper and adds missing foreign-key indexes.
3. `20260520160032_production_runtime_support`: enables realtime publication for messaging/match/notification tables, adds thread timestamp triggers, notification queue triggers, account deletion requests, and nearby listing search.
4. `20260520160959_account_deletion_index`: adds the account deletion request foreign-key index flagged by the Supabase performance advisor.

Local migration files live in `supabase/migrations/`.

## Edge Functions

1. `delete-account`: authenticated function that validates the bearer token, writes an account deletion request, and deletes the Supabase Auth user through the service-role admin API.
2. `send-push-notifications`: authenticated function scaffold that reads pending notification rows and reports queue state. It still needs APNs signing and delivery configuration before production use.

Local function source lives in `supabase/functions/`.

## Implemented Client Wiring

1. `AuthSessionStore` handles email/password signup, signin, password recovery, session persistence, sign out, delete account, and APNs token upload once a session exists.
2. `SupabaseQuestBondRepository` mirrors profile, listing, swipe, message, report, and block actions into Supabase.
3. `QuestBondStore` loads backend profile/listings when signed in and keeps local seed/offline data available for development fallback.
4. Listing and profile location fields geocode selected suggestions into coordinates.
5. Discovery can filter locally loaded coordinate-backed listings by miles.
6. Message and listing text pass through a local moderation preflight before being saved or sent.

## RLS Policy Shape

RLS is enabled on public tables.

- `profiles`: users manage their own profile and can read social profile fields.
- `listings`: authenticated users can read active listings; owners can manage their own listings.
- `listing_roles`: follows listing ownership/read access.
- `swipes`: users can create and read their own swipe decisions.
- `matches`: visible to users who own either listing.
- `message_threads`: visible to participants through match ownership.
- `messages`: users can read/send only inside authorized match threads.
- `reports`: users can create reports; moderator review tooling is still needed.
- `blocks`: users manage their own block records.
- `notifications`: users can read/update their own notification rows; server-side functions process delivery.
- `account_deletion_requests`: users can create/read their own deletion requests.

## Production Follow-Up

1. Add the Supabase Swift package or a maintained WebSocket client for actual Realtime subscriptions.
2. Make match creation server-authoritative, preferably in an RPC or Edge Function that atomically creates reciprocal matches and threads.
3. Complete APNs delivery in the notification Edge Function.
4. Add a backend moderation Edge Function and require it before publishing listings or delivering messages.
5. Move auth session storage to Keychain.
6. Add Supabase Storage policies for avatars and listing media.
7. Add admin-only report review and audit tooling.
8. Keep running Supabase advisors after schema changes and before every external release.
