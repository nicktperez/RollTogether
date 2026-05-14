# QuestBond Improvement Backlog

## Social And Trust

- Add Apple Sign-In and profile verification.
- Gate all direct contact details behind matched chats.
- Add block, report, mute, and unmatch.
- Add OpenAI moderation or similar checks for messages, profile text, and listing text.
- Add Cloudflare Turnstile or similar abuse protection if spam appears.
- Add profile completeness scoring.
- Add lightweight DM/table reputation after sessions.
- Add moderation queues for reported profiles and messages.

## Matching

- Add availability windows instead of free-text schedules.
- Add MapKit or location autocomplete for in-person discovery.
- Add distance filtering for in-person games.
- Add campaign commitment: one-shot, short arc, long campaign, West Marches.
- Add table sliders: roleplay, combat, puzzles, exploration, rules strictness.
- Add safety and comfort tags: Session Zero, lines/veils, beginner-friendly, LGBTQ+ friendly.
- Add platform tags: Discord, Roll20, Foundry, Owlbear Rodeo, D&D Beyond.
- Add saved searches and match alerts.

## Chat

- Add unread counts and read receipts.
- Add typing indicators after Realtime is connected.
- Add Session Zero templates.
- Add share-contact cards for Discord/email only after both sides opt in.
- Add calendar proposal messages.
- Add image attachments for character sheets or campaign primers.

## Product

- Add onboarding quiz.
- Add profile/listing preview before publishing.
- Add draft listings.
- Add searchable listing directory separate from swipe discovery.
- Add Apple Push Notifications for new matches, new messages, and listing interest.
- Add premium features later: boosts, advanced filters, extra active listings.
- Add RevenueCat when subscriptions become part of the product.

## Engineering

- Split `QuestBondApp.swift` into models, store, matching, and view files.
- Add unit tests for match scoring and filter behavior.
- Add UI tests for create, connect, chat, and persistence flows.
- Add Supabase repositories behind protocols so local mock data remains available.
- Add crash reporting with Sentry before external testing.
- Add a real asset catalog app icon set before TestFlight.
