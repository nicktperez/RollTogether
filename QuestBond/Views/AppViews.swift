import AuthenticationServices
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: AuthSessionStore
    @EnvironmentObject private var store: QuestBondStore
    @AppStorage("questbond.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if auth.isAuthenticated {
                TabView {
                    DiscoverView()
                        .tabItem {
                            Label("Discover", systemImage: "rectangle.stack.person.crop")
                        }

                    ChatsView()
                        .tabItem {
                            Label("Chats", systemImage: "bubble.left.and.bubble.right")
                        }

                    MoreView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .tabItem {
                            Label("More", systemImage: "ellipsis")
                        }
                }
                .tint(.questPrimary)
                .fullScreenCover(isPresented: Binding(get: { !hasCompletedOnboarding }, set: { hasCompletedOnboarding = !$0 })) {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
                .task(id: auth.accessToken) {
                    store.configureBackend(accessTokenProvider: { auth.accessToken }, userIDProvider: { auth.userID })
                    await store.loadBackendData()
                    await store.registerPushToken(NotificationRegistrationService.shared.deviceToken, auth: auth)
                }
            } else {
                AuthView()
            }
        }
        .alert("Moderation", isPresented: Binding(get: { store.moderationWarning != nil }, set: { if !$0 { store.moderationWarning = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.moderationWarning ?? "")
        }
    }
}

struct AuthView: View {
    @EnvironmentObject private var auth: AuthSessionStore
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isCreatingAccount = false

    var body: some View {
        ZStack {
            QuestBackground()

            VStack(spacing: 20) {
                Spacer()

                Image("QuestBondMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.questBrass.opacity(0.65), lineWidth: 1))

                VStack(spacing: 8) {
                    Text("RollTogether")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.questParchment)
                    Text("Sign in to sync listings, matches, chats, reports, and notifications.")
                        .font(.body)
                        .foregroundStyle(Color.questMutedText)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    if isCreatingAccount {
                        TextField("Display name", text: $displayName)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                    }

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .textContentType(isCreatingAccount ? .newPassword : .password)
                }
                .textFieldStyle(.roundedBorder)

                if let lastError = auth.lastError {
                    Text(lastError)
                        .font(.footnote)
                        .foregroundStyle(lastError.contains("requested") ? Color.questBrass : .red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        if isCreatingAccount {
                            await auth.signUp(email: email, password: password, displayName: displayName.isEmpty ? "New Adventurer" : displayName)
                        } else {
                            await auth.signIn(email: email, password: password)
                        }
                    }
                } label: {
                    Text(auth.isWorking ? "Working..." : (isCreatingAccount ? "Create Account" : "Sign In"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent)
                .tint(.questBrass)
                .foregroundStyle(Color.questInk)
                .disabled(auth.isWorking || email.isEmpty || password.count < 6)

                Button {
                    Task { await auth.signInWithApple() }
                } label: {
                    Label("Sign in with Apple", systemImage: "apple.logo")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .foregroundStyle(.white)
                .disabled(auth.isWorking)

                HStack {
                    Button(isCreatingAccount ? "Have an account? Sign in" : "Create account") {
                        isCreatingAccount.toggle()
                    }

                    Spacer()

                    Button("Reset password") {
                        Task { await auth.recoverPassword(email: email) }
                    }
                    .disabled(email.isEmpty)
                }
                .font(.footnote)
                .foregroundStyle(Color.questBrass)

                Spacer()
            }
            .padding(24)
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: QuestBondStore
    var complete: () -> Void

    var body: some View {
        ZStack {
            QuestBackground()

            VStack(spacing: 22) {
                Spacer(minLength: 18)

                Image("QuestBondMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 138, height: 138)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.questBrass.opacity(0.65), lineWidth: 1)
                    )

                VStack(spacing: 10) {
                    Text("Find the right table")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.questParchment)
                        .multilineTextAlignment(.center)

                    Text("Create searches for different campaigns, match with groups or players, then use private chat to compare expectations before sharing contact info.")
                        .font(.body)
                        .foregroundStyle(Color.questMutedText)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    OnboardingPoint(icon: "rectangle.stack.person.crop", title: "Discover", text: "Browse groups or players by fit score.")
                    OnboardingPoint(icon: "plus.circle", title: "Start another search", text: "Use + for different roles, schedules, or styles.")
                    OnboardingPoint(icon: "bubble.left.and.bubble.right", title: "Chat after connecting", text: "Ask Session Zero questions first.")
                }

                SessionZeroCompactEditor(profile: $store.sessionZero)

                Spacer()

                Button(action: complete) {
                    Text("Start Matching")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.questBrass)
                .foregroundStyle(Color.questInk)
            }
            .padding(24)
        }
    }
}

struct OnboardingPoint: View {
    var icon: String
    var title: String
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.questBrass)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.questParchment)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Color.questMutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.questGlass, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.questBrass.opacity(0.28), lineWidth: 1)
        )
    }
}

struct SessionZeroCompactEditor: View {
    @Binding var profile: SessionZeroProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Session Zero Fit", systemImage: "shield.lefthalf.filled")
                .font(.headline)
                .foregroundStyle(Color.questParchment)

            TextField("Tone", text: $profile.tone)
                .textFieldStyle(.roundedBorder)
            TextField("Safety tools", text: $profile.safetyTools)
                .textFieldStyle(.roundedBorder)
            TextField("Rules style", text: $profile.rulesStyle)
                .textFieldStyle(.roundedBorder)
        }
        .padding(14)
        .background(Color.questGlass, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.questBrass.opacity(0.28), lineWidth: 1)
        )
    }
}

struct DiscoverView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case groupsBrowse = "Groups Browse"
        case partiesBrowse = "Parties Browse"

        var id: String { rawValue }
    }

    @EnvironmentObject private var store: QuestBondStore
    @State private var mode: Mode = .partiesBrowse
    @State private var showingNewSearch = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 16) {
                        BrandHero()
                        ProfileStrengthCard()
                        StatsStrip()

                        Picker("Browse Mode", selection: $mode) {
                            ForEach(Mode.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(.questPrimary)

                        if mode == .groupsBrowse {
                            GroupBrowsingView()
                        } else {
                            PartyBrowsingView()
                        }
                    }
                    .padding()
                    .padding(.bottom, 84)
                }
                .background(QuestBackground())

                Button {
                    showingNewSearch = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(Color.questInk)
                        .frame(width: 58, height: 58)
                        .background(Color.questBrass, in: Circle())
                        .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
                }
                .accessibilityLabel("Start new search")
                .padding(.trailing, 18)
                .padding(.bottom, 18)
            }
            .navigationTitle("QuestBond")
            .toolbar {
                Button {
                    showingNewSearch = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Start new search")
            }
            .sheet(isPresented: $showingNewSearch) {
                NewSearchSheet()
            }
        }
    }
}

struct StatsStrip: View {
    @EnvironmentObject private var store: QuestBondStore

    var body: some View {
        HStack(spacing: 8) {
            StatTile(value: store.groups.count, label: "Groups", icon: "person.3")
            StatTile(value: store.parties.count, label: "Parties", icon: "person.2")
            StatTile(value: store.matches.count, label: "Links", icon: "link")
        }
    }
}

struct QuestBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.questInk, Color.questDeepGreen, Color.questBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct BrandHero: View {
    var body: some View {
        HStack(spacing: 14) {
            Image("QuestBondMark")
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.questBrass.opacity(0.7), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text("QuestBond")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.questParchment)
                Text("Find a table, fill a party, then talk through the fit.")
                    .font(.subheadline)
                    .foregroundStyle(Color.questMutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.questGlass, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.questBrass.opacity(0.45), lineWidth: 1)
        )
    }
}

struct StatTile: View {
    var value: Int
    var label: String
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Color.questBrass)
            Text(value.formatted())
                .font(.title3.bold())
                .foregroundStyle(Color.questParchment)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.questMutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.questGlass, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.questBrass.opacity(0.25), lineWidth: 1)
        )
    }
}

struct GroupBrowsingView: View {
    @EnvironmentObject private var store: QuestBondStore

    var body: some View {
        VStack(spacing: 14) {
            GroupBrowseFilterForm()

            if let candidate = store.groupBrowseCandidates.first {
                PartyCandidateCard(candidate: candidate)
                SwipeActions(
                    passAction: { store.swipeGroupCandidate(.pass) },
                    connectAction: { store.swipeGroupCandidate(.connect) }
                )
                CandidateCount(count: store.groupBrowseCandidates.count)
            } else {
                EmptyDiscoveryView(title: "No players match", message: "Adjust filters or create another listing.")
            }
        }
    }
}

struct PartyBrowsingView: View {
    @EnvironmentObject private var store: QuestBondStore

    var body: some View {
        VStack(spacing: 14) {
            PartyBrowseFilterForm()

            if let candidate = store.partyBrowseCandidates.first {
                GroupCandidateCard(candidate: candidate)
                SwipeActions(
                    passAction: { store.swipePartyCandidate(.pass) },
                    connectAction: { store.swipePartyCandidate(.connect) }
                )
                CandidateCount(count: store.partyBrowseCandidates.count)
            } else {
                EmptyDiscoveryView(title: "No groups match", message: "Adjust filters or create another listing.")
            }
        }
    }
}

struct GroupBrowseFilterForm: View {
    @EnvironmentObject private var store: QuestBondStore
    @State private var saved = false

    var body: some View {
        FilterPanel(title: "Group Search") {
            Picker("Your Group", selection: $store.groupFilters.ownerID) {
                ForEach(store.groups) { group in
                    Text(group.name).tag(Optional(group.id))
                }
            }

            Picker("Before: Session", selection: $store.groupFilters.preMode) {
                ForEach([SessionMode.any, .online, .inPerson]) { Text($0.label).tag($0) }
            }

            Picker("Before: Experience", selection: $store.groupFilters.preExperience) {
                ForEach(ExperienceLevel.allCases) { Text($0.label).tag($0) }
            }

            Stepper("Minimum party size: \(store.groupFilters.minimumPartySize)", value: $store.groupFilters.minimumPartySize, in: 1...6)

            Stepper("Distance: \(store.groupFilters.maximumDistanceMiles) mi", value: $store.groupFilters.maximumDistanceMiles, in: 5...250, step: 5)

            Picker("After: Session", selection: $store.groupFilters.postMode) {
                ForEach([SessionMode.any, .online, .inPerson]) { Text($0.label).tag($0) }
            }

            Picker("After: Campaign", selection: $store.groupFilters.postCampaign) {
                ForEach(CampaignStyle.allCases) { Text($0.label).tag($0) }
            }

            TextField("Search name, location, vibe", text: $store.groupFilters.query)
                .textInputAutocapitalization(.words)

            Button {
                store.saveCurrentGroupSearch()
                saved = true
            } label: {
                Label(saved ? "Saved Search" : "Save Search + Alerts", systemImage: saved ? "checkmark.circle.fill" : "bell.badge")
            }
            .buttonStyle(.bordered)
            .tint(.questPrimary)
        }
    }
}

struct PartyBrowseFilterForm: View {
    @EnvironmentObject private var store: QuestBondStore
    @State private var saved = false

    var body: some View {
        FilterPanel(title: "Party Search") {
            Picker("Your Party", selection: $store.partyFilters.ownerID) {
                ForEach(store.parties) { party in
                    Text(party.name).tag(Optional(party.id))
                }
            }

            Picker("Before: Session", selection: $store.partyFilters.preMode) {
                ForEach([SessionMode.any, .online, .inPerson]) { Text($0.label).tag($0) }
            }

            Picker("Before: Campaign", selection: $store.partyFilters.preCampaign) {
                ForEach(CampaignStyle.allCases) { Text($0.label).tag($0) }
            }

            Stepper("Minimum open slots: \(store.partyFilters.minimumOpenSlots)", value: $store.partyFilters.minimumOpenSlots, in: 1...8)

            Stepper("Distance: \(store.partyFilters.maximumDistanceMiles) mi", value: $store.partyFilters.maximumDistanceMiles, in: 5...250, step: 5)

            Picker("After: Session", selection: $store.partyFilters.postMode) {
                ForEach([SessionMode.any, .online, .inPerson]) { Text($0.label).tag($0) }
            }

            Picker("After: Table Level", selection: $store.partyFilters.postExperience) {
                ForEach(ExperienceLevel.allCases) { Text($0.label).tag($0) }
            }

            TextField("Search name, location, style", text: $store.partyFilters.query)
                .textInputAutocapitalization(.words)

            Button {
                store.saveCurrentPartySearch()
                saved = true
            } label: {
                Label(saved ? "Saved Search" : "Save Search + Alerts", systemImage: saved ? "checkmark.circle.fill" : "bell.badge")
            }
            .buttonStyle(.bordered)
            .tint(.questPrimary)
        }
    }
}

struct FilterPanel<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(.top, 12)
        } label: {
            Label(title, systemImage: "line.3.horizontal.decrease.circle")
                .font(.headline)
                .foregroundStyle(Color.questParchment)
        }
        .padding(14)
        .background(Color.questGlass, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.questBrass.opacity(0.35), lineWidth: 1)
        )
    }
}

struct GroupCandidateCard: View {
    var candidate: Candidate<GroupListing>

    var body: some View {
        CandidateShell(score: candidate.score) {
            let group = candidate.entry
            CardHeader(title: group.name, subtitle: "\(group.mode.label) | \(group.campaignStyle.label) | \(group.openSlots) open")
            TagCloud(
                tags: [
                    group.tableExperience.label,
                    "Wants \(group.lookingForPartySize.label)",
                    group.location.isEmpty ? "No location" : group.location,
                    group.schedule.isEmpty ? "Flexible" : group.schedule
                ]
            )
            DescriptionBlock(text: group.characterVibe)
            DescriptionBlock(text: group.about)
            ReasonList(reasons: candidate.reasons)
            ContactLine(contact: group.contact)
        }
    }
}

struct PartyCandidateCard: View {
    var candidate: Candidate<PartyListing>

    var body: some View {
        CandidateShell(score: candidate.score) {
            let party = candidate.entry
            CardHeader(title: party.name, subtitle: "\(MatchingService.partySizeLabel(party.partySize)) (\(party.partySize)) | \(party.mode.label) | \(party.experience.label)")
            TagCloud(
                tags: [
                    "Looking for \(party.lookingForCampaign.label)",
                    party.location.isEmpty ? "No location" : party.location,
                    party.schedule.isEmpty ? "Flexible" : party.schedule,
                    party.rolesCovered.isEmpty ? "Roles open" : party.rolesCovered.map(\.label).joined(separator: ", ")
                ]
            )
            DescriptionBlock(text: party.vibe)
            DescriptionBlock(text: party.about)
            ReasonList(reasons: candidate.reasons)
            ContactLine(contact: party.contact)
        }
    }
}

struct CandidateShell<Content: View>: View {
    var score: Int
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    content
                }
                Spacer(minLength: 8)
                Text("\(score)%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.questPrimary, in: Capsule())
                    .accessibilityLabel("Fit score \(score) percent")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.questSurface, Color.questParchment],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.questBrass.opacity(0.55), lineWidth: 1)
        )
    }
}

struct CardHeader: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
                .lineLimit(2)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct TagCloud: View {
    var tags: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags.filter { !$0.isEmpty }, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.questTag, in: Capsule())
            }
        }
    }
}

struct DescriptionBlock: View {
    var text: String

    var body: some View {
        if !text.isEmpty {
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}

struct ReasonList: View {
    var reasons: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(reasons, id: \.self) { reason in
                Label(reason, systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ContactLine: View {
    var contact: String

    var body: some View {
        Label("Private chat unlocks after connect", systemImage: "lock.open")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

struct SwipeActions: View {
    var passAction: () -> Void
    var connectAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: passAction) {
                Label("Pass", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.questDanger)

            Button(action: connectAction) {
                Label("Connect", systemImage: "link")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.questSuccess)
        }
    }
}

struct CandidateCount: View {
    var count: Int

    var body: some View {
        Text("\(count) candidate\(count == 1 ? "" : "s") available")
            .font(.footnote)
            .foregroundStyle(Color.questMutedText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyDiscoveryView: View {
    var title: String
    var message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: "magnifyingglass", description: Text(message))
            .padding(.vertical, 30)
            .foregroundStyle(Color.questMutedText)
    }
}

struct NewSearchSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        CreatePartyView()
                    } label: {
                        Label("Find a Group", systemImage: "person.crop.circle.badge.plus")
                    }

                    NavigationLink {
                        CreateGroupView()
                    } label: {
                        Label("Find Players", systemImage: "person.3.sequence")
                    }
                } header: {
                    Text("Start A New Search")
                } footer: {
                    Text("Create a separate listing when you want different campaign styles, schedules, roles, or online/in-person preferences.")
                }

                Section {
                    NavigationLink {
                        ListingsView()
                    } label: {
                        Label("Manage Listings", systemImage: "list.bullet.rectangle")
                    }
                }
            }
            .navigationTitle("New Setup")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct ChatsView: View {
    @EnvironmentObject private var store: QuestBondStore

    var body: some View {
        NavigationStack {
            List {
                if store.threads.isEmpty {
                    ContentUnavailableView("No chats yet", systemImage: "bubble.left.and.bubble.right", description: Text("Connect with a match in Discover to open a private thread."))
                } else {
                    ForEach(store.threads.sorted { $0.updatedAt > $1.updatedAt }) { thread in
                        NavigationLink {
                            ChatDetailView(thread: thread)
                        } label: {
                            ChatThreadRow(thread: thread, lastMessage: store.messages(for: thread).last)
                        }
                    }
                }
            }
            .navigationTitle("Chats")
        }
    }
}

struct ProfileStrengthCard: View {
    @EnvironmentObject private var store: QuestBondStore

    var body: some View {
        let strength = store.profileStrength
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(strength.label, systemImage: "person.crop.circle.badge.checkmark")
                    .font(.headline)
                    .foregroundStyle(Color.questParchment)
                Spacer()
                Text("\(strength.score)%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.questBrass)
            }

            ProgressView(value: Double(strength.score), total: 100)
                .tint(.questBrass)

            if !strength.missingItems.isEmpty {
                Text("Add \(strength.missingItems.prefix(3).joined(separator: ", ")) to improve match trust.")
                    .font(.caption)
                    .foregroundStyle(Color.questMutedText)
            }
        }
        .padding(14)
        .background(Color.questGlass, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.questBrass.opacity(0.28), lineWidth: 1)
        )
    }
}

struct ChatThreadRow: View {
    var thread: ChatThread
    var lastMessage: ChatMessage?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.questPrimary)
                Text("\(thread.score)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(thread.groupName) + \(thread.partyName)")
                    .font(.headline)
                    .lineLimit(1)
                Text(lastMessage?.text ?? thread.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(thread.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ChatDetailView: View {
    @EnvironmentObject private var store: QuestBondStore
    @EnvironmentObject private var auth: AuthSessionStore
    var thread: ChatThread
    @State private var draft = ""
    @State private var showingReport = false
    @State private var showingFeedback = false
    @State private var showingBlockConfirmation = false

    private var activeThread: ChatThread {
        store.threads.first { $0.id == thread.id } ?? thread
    }

    var body: some View {
        VStack(spacing: 0) {
            MatchContextHeader(thread: activeThread)

            ScrollView {
                LazyVStack(spacing: 10) {
                    MatchContextCards(thread: activeThread)
                    ForEach(store.messages(for: activeThread)) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding()
            }
            .background(Color.questBackground)

            PromptRail(thread: activeThread)

            HStack(spacing: 8) {
                TextField("Ask a question", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button {
                    store.sendMessage(draft, in: activeThread)
                    draft = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.regularMaterial)
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.subscribeToRealtime(thread: activeThread, auth: auth)
        }
        .onDisappear {
            store.disconnectRealtime()
        }
        .toolbar {
            Menu {
                Button(role: .destructive) {
                    showingReport = true
                } label: {
                    Label("Report", systemImage: "exclamationmark.shield")
                }

                Button(role: .destructive) {
                    showingBlockConfirmation = true
                } label: {
                    Label("Block", systemImage: "nosign")
                }

                Button {
                    showingFeedback = true
                } label: {
                    Label("Post-Session Feedback", systemImage: "checklist")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .sheet(isPresented: $showingReport) {
            ReportThreadView(thread: activeThread)
        }
        .sheet(isPresented: $showingFeedback) {
            PostSessionFeedbackView(thread: activeThread)
        }
        .alert("Block this match?", isPresented: $showingBlockConfirmation) {
            Button("Block", role: .destructive) {
                store.blockMatch(in: activeThread)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This adds the match to your local blocked list. Backend enforcement will sync when Supabase is connected.")
        }
    }
}

struct MatchContextCards: View {
    @EnvironmentObject private var store: QuestBondStore
    var thread: ChatThread

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let group = store.group(for: thread) {
                ContextCard(
                    title: group.name,
                    subtitle: "Table looking for \(group.openSlots) player\(group.openSlots == 1 ? "" : "s")",
                    tags: [group.mode.label, group.campaignStyle.label, group.schedule],
                    detail: group.about.isEmpty ? group.characterVibe : group.about
                )
            }

            if let party = store.party(for: thread) {
                ContextCard(
                    title: party.name,
                    subtitle: "\(MatchingService.partySizeLabel(party.partySize)) looking for a table",
                    tags: [party.mode.label, party.experience.label, party.schedule],
                    detail: party.about.isEmpty ? party.vibe : party.about
                )
            }

            ContextCard(
                title: "Session Zero Notes",
                subtitle: "Use this before sharing outside contact info",
                tags: [store.sessionZero.tone, store.sessionZero.rulesStyle],
                detail: store.sessionZero.safetyTools
            )
        }
    }
}

struct ContextCard: View {
    var title: String
    var subtitle: String
    var tags: [String]
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            TagCloud(tags: tags.filter { !$0.isEmpty })
            if !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.questSurface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.questLine, lineWidth: 1)
        )
    }
}

struct PostSessionFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: QuestBondStore
    var thread: ChatThread
    @State private var sentiment: PostSessionFeedback.Sentiment = .greatFit
    @State private var wouldPlayAgain = true
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("How did it go?") {
                    Picker("Fit", selection: $sentiment) {
                        ForEach(PostSessionFeedback.Sentiment.allCases) { sentiment in
                            Text(sentiment.label).tag(sentiment)
                        }
                    }
                    Toggle("Would play again", isOn: $wouldPlayAgain)
                }

                Section("Private Notes") {
                    TextField("What should you remember?", text: $notes, axis: .vertical)
                        .lineLimit(3...7)
                    Text("Safety concerns also create a local report so moderation can sync later.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Table Feedback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.submitFeedback(thread: thread, sentiment: sentiment, wouldPlayAgain: wouldPlayAgain, notes: notes)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReportThreadView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: QuestBondStore
    var thread: ChatThread
    @State private var reason = "Safety concern"
    @State private var details = ""

    private let reasons = ["Safety concern", "Spam", "Harassment", "Misleading listing", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    Picker("Reason", selection: $reason) {
                        ForEach(reasons, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }
                }

                Section("Details") {
                    TextField("What happened?", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        store.reportThread(thread, reason: reason, details: details)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MatchContextHeader: View {
    var thread: ChatThread

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(thread.groupName) + \(thread.partyName)")
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text("\(thread.score)% Fit")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.questPrimary, in: Capsule())
            }

            Text(thread.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.questSurface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.questLine)
                .frame(height: 1)
        }
    }
}

struct ChatBubble: View {
    var message: ChatMessage

    private var alignment: Alignment {
        message.sender == .me ? .trailing : .leading
    }

    private var bubbleColor: Color {
        switch message.sender {
        case .me: .questPrimary
        case .match: .questSurface
        case .system: .questTag
        }
    }

    private var textColor: Color {
        message.sender == .me ? .white : .primary
    }

    var body: some View {
        VStack(alignment: message.sender == .me ? .trailing : .leading, spacing: 4) {
            Text(message.sender == .me ? "You" : message.sender == .match ? "Match" : "QuestBond")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(message.text)
                .font(.body)
                .foregroundStyle(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(bubbleColor, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(message.sender == .me ? Color.clear : Color.questLine, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: alignment)
    }
}

struct PromptRail: View {
    @EnvironmentObject private var store: QuestBondStore
    var thread: ChatThread

    private let prompts = [
        "What tone are you hoping for at the table?",
        "What days and times reliably work?",
        "How rules-strict is the group?",
        "What safety tools do you use?",
        "Is this online, in-person, or hybrid?",
        "What should Session Zero cover?"
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        store.sendPrompt(prompt, in: thread)
                    } label: {
                        Label(prompt, systemImage: "questionmark.bubble")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .buttonStyle(.bordered)
                    .tint(.questPrimary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.questSurface)
    }
}

struct CreateGroupView: View {
    @EnvironmentObject private var store: QuestBondStore
    @State private var draft = GroupDraft()

    var body: some View {
        NavigationStack {
            Form {
                Section("Group") {
                    TextField("Group name", text: $draft.name)
                    Picker("Session", selection: $draft.mode) {
                        ForEach([SessionMode.online, .inPerson, .hybrid]) { Text($0.label).tag($0) }
                    }
                    LocationField(title: "Location or time zone", text: $draft.location, latitude: $draft.latitude, longitude: $draft.longitude)
                    Stepper("Open slots: \(draft.openSlots)", value: $draft.openSlots, in: 1...8)
                    TextField("Schedule", text: $draft.schedule)
                }

                Section("Table Fit") {
                    Picker("Campaign", selection: $draft.campaignStyle) {
                        ForEach(CampaignStyle.allCases.filter { $0 != .any }) { Text($0.label).tag($0) }
                    }
                    Picker("Table level", selection: $draft.tableExperience) {
                        ForEach(ExperienceLevel.allCases.filter { $0 != .any }) { Text($0.label).tag($0) }
                    }
                    Picker("Party size wanted", selection: $draft.lookingForPartySize) {
                        ForEach(PartySizePreference.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Player level wanted", selection: $draft.desiredExperience) {
                        ForEach(ExperienceLevel.allCases) { Text($0.label).tag($0) }
                    }
                    RoleSelection(title: "Desired Roles", selection: $draft.desiredRoles)
                }

                Section("Details") {
                    TextField("Character vibe wanted", text: $draft.characterVibe, axis: .vertical)
                    TextField("About the group", text: $draft.about, axis: .vertical)
                    TextField("Contact", text: $draft.contact)
                }

                Button {
                    store.addGroup(draft.listing)
                    draft = GroupDraft()
                } label: {
                    Label("Publish Group", systemImage: "plus.circle.fill")
                }
                .disabled(!draft.canSubmit)
            }
            .navigationTitle("Create Group")
        }
    }
}

struct CreatePartyView: View {
    @EnvironmentObject private var store: QuestBondStore
    @State private var draft = PartyDraft()

    var body: some View {
        NavigationStack {
            Form {
                Section("Party") {
                    TextField("Player or party name", text: $draft.name)
                    Stepper("Party size: \(draft.partySize)", value: $draft.partySize, in: 1...6)
                    Picker("Session", selection: $draft.mode) {
                        ForEach([SessionMode.online, .inPerson, .hybrid]) { Text($0.label).tag($0) }
                    }
                    LocationField(title: "Location or time zone", text: $draft.location, latitude: $draft.latitude, longitude: $draft.longitude)
                    TextField("Schedule", text: $draft.schedule)
                }

                Section("Looking For") {
                    Picker("Experience", selection: $draft.experience) {
                        ForEach(ExperienceLevel.allCases.filter { $0 != .any }) { Text($0.label).tag($0) }
                    }
                    Picker("Campaign", selection: $draft.lookingForCampaign) {
                        ForEach(CampaignStyle.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Table level", selection: $draft.lookingForExperience) {
                        ForEach(ExperienceLevel.allCases) { Text($0.label).tag($0) }
                    }
                    RoleSelection(title: "Roles Covered", selection: $draft.rolesCovered)
                }

                Section("Details") {
                    TextField("Character vibe", text: $draft.vibe, axis: .vertical)
                    TextField("About you or your party", text: $draft.about, axis: .vertical)
                    TextField("Contact", text: $draft.contact)
                }

                Button {
                    store.addParty(draft.listing)
                    draft = PartyDraft()
                } label: {
                    Label("Publish Party", systemImage: "plus.circle.fill")
                }
                .disabled(!draft.canSubmit)
            }
            .navigationTitle("Create Party")
        }
    }
}

struct GroupDraft {
    var name = ""
    var mode: SessionMode = .online
    var location = ""
    var latitude: Double?
    var longitude: Double?
    var openSlots = 1
    var campaignStyle: CampaignStyle = .heroic
    var tableExperience: ExperienceLevel = .new
    var lookingForPartySize: PartySizePreference = .any
    var desiredExperience: ExperienceLevel = .any
    var desiredRoles: [PartyRole] = []
    var characterVibe = ""
    var schedule = ""
    var about = ""
    var contact = ""

    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var listing: GroupListing {
        GroupListing(
            name: name,
            mode: mode,
            location: location,
            latitude: latitude,
            longitude: longitude,
            openSlots: openSlots,
            campaignStyle: campaignStyle,
            tableExperience: tableExperience,
            lookingForPartySize: lookingForPartySize,
            desiredExperience: desiredExperience,
            desiredRoles: desiredRoles,
            characterVibe: characterVibe,
            schedule: schedule,
            about: about,
            contact: contact
        )
    }
}

struct PartyDraft {
    var name = ""
    var partySize = 1
    var mode: SessionMode = .online
    var location = ""
    var latitude: Double?
    var longitude: Double?
    var experience: ExperienceLevel = .new
    var rolesCovered: [PartyRole] = []
    var lookingForCampaign: CampaignStyle = .any
    var lookingForExperience: ExperienceLevel = .any
    var vibe = ""
    var schedule = ""
    var about = ""
    var contact = ""

    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var listing: PartyListing {
        PartyListing(
            name: name,
            partySize: partySize,
            mode: mode,
            location: location,
            latitude: latitude,
            longitude: longitude,
            experience: experience,
            rolesCovered: rolesCovered,
            lookingForCampaign: lookingForCampaign,
            lookingForExperience: lookingForExperience,
            vibe: vibe,
            schedule: schedule,
            about: about,
            contact: contact
        )
    }
}

struct RoleSelection: View {
    var title: String
    @Binding var selection: [PartyRole]

    var body: some View {
        Section(title) {
            ForEach(PartyRole.allCases) { role in
                Toggle(role.label, isOn: binding(for: role))
            }
        }
    }

    private func binding(for role: PartyRole) -> Binding<Bool> {
        Binding {
            selection.contains(role)
        } set: { isSelected in
            if isSelected {
                if !selection.contains(role) {
                    selection.append(role)
                }
            } else {
                selection.removeAll { $0 == role }
            }
        }
    }
}

struct LocationField: View {
    var title: String
    @Binding var text: String
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    @StateObject private var search = LocationSearchService()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(title, text: $text)
                .onChange(of: text) { _, newValue in
                    search.query = newValue
                }

            if !search.suggestions.isEmpty {
                ForEach(search.suggestions, id: \.self) { suggestion in
                    Button {
                        text = suggestion
                        search.query = ""
                        Task {
                            if let coordinate = await search.geocode(suggestion) {
                                latitude = coordinate.latitude
                                longitude = coordinate.longitude
                            }
                        }
                    } label: {
                        Label(suggestion, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }

            if let latitude, let longitude {
                Text("Coordinates saved: \(latitude.formatted(.number.precision(.fractionLength(3)))), \(longitude.formatted(.number.precision(.fractionLength(3))))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ListingsView: View {
    @EnvironmentObject private var store: QuestBondStore

    var body: some View {
        NavigationStack {
            List {
                Section("Groups") {
                    ForEach(store.groups) { group in
                        GroupListingRow(group: group)
                    }
                }

                Section("Players and Parties") {
                    ForEach(store.parties) { party in
                        PartyListingRow(party: party)
                    }
                }
            }
            .navigationTitle("Listings")
        }
    }
}

struct GroupListingRow: View {
    var group: GroupListing

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(group.name)
                .font(.headline)
            Text("\(group.mode.label) | \(group.openSlots) open | \(group.campaignStyle.label)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(group.about.isEmpty ? group.characterVibe : group.about)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PartyListingRow: View {
    var party: PartyListing

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(party.name)
                .font(.headline)
            Text("\(MatchingService.partySizeLabel(party.partySize)) | \(party.mode.label) | \(party.experience.label)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(party.about.isEmpty ? party.vibe : party.about)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct MatchesView: View {
    @EnvironmentObject private var store: QuestBondStore

    var body: some View {
        NavigationStack {
            List {
                if store.matches.isEmpty {
                    ContentUnavailableView("No connections yet", systemImage: "link", description: Text("Connect from Discover to save matches."))
                } else {
                    ForEach(store.matches.sorted { $0.connectedAt > $1.connectedAt }) { match in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(match.groupName) + \(match.partyName)")
                                .font(.headline)
                            Text("Score \(match.score)% | Started by \(match.initiatedBy)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(match.connectedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Matches")
            .toolbar {
                Button("Clear") {
                    store.clearMatches()
                }
                .disabled(store.matches.isEmpty)
            }
        }
    }
}

struct MoreView: View {
    @EnvironmentObject private var store: QuestBondStore
    @EnvironmentObject private var auth: AuthSessionStore
    @Binding var hasCompletedOnboarding: Bool
    @State private var confirmingDelete = false
    @State private var deleteReason = "User requested deletion from iOS app"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image("QuestBondMark")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 54, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(store.currentUser.displayName)
                                .font(.headline)
                            Text(store.currentUser.handle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let email = auth.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Create") {
                    NavigationLink {
                        CreatePartyView()
                    } label: {
                        Label("New Group Search", systemImage: "person.crop.circle.badge.plus")
                    }

                    NavigationLink {
                        CreateGroupView()
                    } label: {
                        Label("New Player Search", systemImage: "person.3.sequence")
                    }
                }

                Section("Manage") {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Label("Profile", systemImage: "person.crop.circle")
                    }

                    NavigationLink {
                        ListingsView()
                    } label: {
                        Label("Listings", systemImage: "list.bullet.rectangle")
                    }

                    NavigationLink {
                        MatchesView()
                    } label: {
                        Label("Matches", systemImage: "link")
                    }

                    NavigationLink {
                        SavedSearchesView()
                    } label: {
                        Label("Saved Searches & Alerts", systemImage: "bell.badge")
                    }

                    NavigationLink {
                        OrganizerDashboardView()
                    } label: {
                        Label("DM Organizer Dashboard", systemImage: "tablecells")
                    }

                    NavigationLink {
                        FeedbackHistoryView()
                    } label: {
                        Label("Post-Session Feedback", systemImage: "checklist")
                    }
                }

                Section("Backend Readiness") {
                    Text(store.backendStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    BackendStatusView()

                    NavigationLink {
                        ServiceRoadmapView()
                    } label: {
                        Label("Services & Data Model", systemImage: "server.rack")
                    }
                }

                Section("Help") {
                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Replay Onboarding", systemImage: "sparkles")
                    }
                }

                Section("Account") {
                    Button {
                        auth.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }

                    Button(role: .destructive) {
                        confirmingDelete = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("More")
            .alert("Delete account?", isPresented: $confirmingDelete) {
                TextField("Reason optional", text: $deleteReason)
                Button("Delete Everywhere", role: .destructive) {
                    Task {
                        await auth.deleteAccount(reason: deleteReason)
                        store.deleteLocalAccount()
                        hasCompletedOnboarding = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This requests backend account deletion through Supabase, then clears local profile data, listings, matches, chats, and decisions from this device.")
            }
        }
    }
}

struct BackendStatusView: View {
    @State private var isChecking = false
    @State private var isReachable: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Supabase", systemImage: "server.rack")
                Spacer()
                statusLabel
            }

            Text("Project \(SupabaseConfig.projectRef) is configured with the publishable key and production tables.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(isChecking ? "Checking..." : "Check Connection") {
                Task { await checkConnection() }
            }
            .disabled(isChecking)
        }
        .task {
            if isReachable == nil {
                await checkConnection()
            }
        }
    }

    private var statusLabel: some View {
        Group {
            if let isReachable {
                Text(isReachable ? "Connected" : "Offline")
                    .font(.caption.bold())
                    .foregroundStyle(isReachable ? Color.questPrimary : .red)
            } else {
                Text("Not checked")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }

    @MainActor private func checkConnection() async {
        isChecking = true
        isReachable = await SupabaseClient().checkConnection()
        isChecking = false
    }
}

struct ServiceRoadmapView: View {
    private let usefulServices = [
        RoadmapItem(name: "Apple Push Notifications", detail: "new match and message alerts", icon: "bell.badge"),
        RoadmapItem(name: "MapKit / Location Autocomplete", detail: "in-person group discovery", icon: "map"),
        RoadmapItem(name: "OpenAI Moderation", detail: "message and profile safety checks", icon: "checkmark.shield"),
        RoadmapItem(name: "Sentry", detail: "crash and error tracking", icon: "waveform.path.ecg"),
        RoadmapItem(name: "RevenueCat", detail: "subscriptions for premium filters or boosts", icon: "creditcard"),
        RoadmapItem(name: "Cloudflare Turnstile", detail: "abuse protection when spam appears", icon: "lock.shield")
    ]

    private let dataModel = [
        RoadmapItem(name: "users", detail: "account identity", icon: "person"),
        RoadmapItem(name: "profiles", detail: "display name, avatar, bio, location, experience, preferences", icon: "person.text.rectangle"),
        RoadmapItem(name: "listings", detail: "group or party listing", icon: "list.bullet.rectangle"),
        RoadmapItem(name: "listing_roles", detail: "desired or covered roles", icon: "tag"),
        RoadmapItem(name: "swipes", detail: "pass/connect decisions", icon: "hand.tap"),
        RoadmapItem(name: "matches", detail: "confirmed pairings", icon: "link"),
        RoadmapItem(name: "messages", detail: "chat messages", icon: "message"),
        RoadmapItem(name: "message_threads", detail: "one per match", icon: "bubble.left.and.bubble.right"),
        RoadmapItem(name: "reports", detail: "safety reports", icon: "exclamationmark.shield"),
        RoadmapItem(name: "blocks", detail: "blocked users/listings", icon: "nosign"),
        RoadmapItem(name: "notifications", detail: "push notification queue", icon: "bell")
    ]

    var body: some View {
        List {
            Section("Also Useful") {
                ForEach(usefulServices) { item in
                    RoadmapRow(item: item)
                }
            }

            Section("Core Data Model") {
                ForEach(dataModel) { item in
                    RoadmapRow(item: item)
                }
            }
        }
        .navigationTitle("Backend Plan")
    }
}

struct RoadmapItem: Identifiable {
    var id: String { name }
    var name: String
    var detail: String
    var icon: String
}

struct RoadmapRow: View {
    var item: RoadmapItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.icon)
                .foregroundStyle(Color.questPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.headline)
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: QuestBondStore
    @EnvironmentObject private var auth: AuthSessionStore

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image("QuestBondMark")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Display name", text: $store.currentUser.displayName)
                                .font(.title3.bold())
                            TextField("Handle", text: $store.currentUser.handle)
                                .foregroundStyle(.secondary)
                                .textInputAutocapitalization(.never)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Profile") {
                    LocationField(
                        title: "Location",
                        text: $store.currentUser.location,
                        latitude: $store.currentUser.latitude,
                        longitude: $store.currentUser.longitude
                    )
                    TextField("Bio", text: $store.currentUser.bio, axis: .vertical)
                        .lineLimit(2...5)
                    Picker("Favorite role", selection: $store.currentUser.favoriteRole) {
                        ForEach(PartyRole.allCases) { role in
                            Text(role.label).tag(role)
                        }
                    }
                    Picker("Preferred mode", selection: $store.currentUser.preferredMode) {
                        ForEach([SessionMode.online, .inPerson, .hybrid]) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                }

                Section("Table Safety") {
                    TextField("Safety note", text: $store.currentUser.safetyNote, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Session Zero Compatibility") {
                    TextField("Tone", text: $store.sessionZero.tone)
                    TextField("Safety tools", text: $store.sessionZero.safetyTools, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Rules style", text: $store.sessionZero.rulesStyle)
                    TextField("Homebrew comfort", text: $store.sessionZero.homebrewComfort)
                    TextField("Schedule reliability", text: $store.sessionZero.scheduleReliability)
                    TextField("Contact boundary", text: $store.sessionZero.contactBoundary)
                }

                Section("Profile Strength") {
                    let strength = store.profileStrength
                    HStack {
                        Text(strength.label)
                        Spacer()
                        Text("\(strength.score)%")
                            .monospacedDigit()
                            .foregroundStyle(Color.questPrimary)
                    }
                    ProgressView(value: Double(strength.score), total: 100)
                    if !strength.missingItems.isEmpty {
                        Text("Missing: \(strength.missingItems.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Sync") {
                    Button {
                        Task { await store.saveProfileToBackend(auth: auth) }
                    } label: {
                        Label("Save Profile to Supabase", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                Section("Social Roadmap") {
                    Label("Private chat is created after connecting.", systemImage: "bubble.left.and.bubble.right")
                    Label("Public contact info stays hidden by default.", systemImage: "lock")
                    Label("Reports, blocks, and account auth now sync through Supabase.", systemImage: "shield")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct SavedSearchesView: View {
    @EnvironmentObject private var store: QuestBondStore

    var body: some View {
        List {
            if store.savedSearches.isEmpty {
                ContentUnavailableView("No saved searches", systemImage: "bell.badge", description: Text("Save filters from Discover to get ready for match alerts."))
            } else {
                ForEach(store.savedSearches) { search in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(search.name)
                                    .font(.headline)
                                Text(search.kind == .group ? "Finding players" : "Finding groups")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(search.candidateCount)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Color.questPrimary)
                        }

                        Text(search.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Button {
                                store.applySavedSearch(search)
                            } label: {
                                Label("Apply", systemImage: "line.3.horizontal.decrease.circle")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                store.toggleSavedSearchAlerts(search)
                            } label: {
                                Label(search.alertsEnabled ? "Alerts On" : "Alerts Off", systemImage: search.alertsEnabled ? "bell.fill" : "bell.slash")
                            }
                            .buttonStyle(.bordered)
                            .tint(search.alertsEnabled ? .questPrimary : .secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: store.deleteSavedSearches)
            }
        }
        .navigationTitle("Saved Searches")
    }
}

struct OrganizerDashboardView: View {
    @EnvironmentObject private var store: QuestBondStore

    var body: some View {
        List {
            Section {
                if let group = store.groupOwner {
                    Text("Recruiting for: \(group.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Use Group Search filters to rank singles, duos, trios, and full parties by role coverage, schedule, mode, and fit score.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Top Player/Party Candidates") {
                let rows = store.candidateComparisonRows()
                if rows.isEmpty {
                    ContentUnavailableView("No candidates", systemImage: "tablecells", description: Text("Adjust Group Search filters or add more listings."))
                } else {
                    ForEach(rows) { row in
                        OrganizerComparisonRowView(row: row)
                    }
                }
            }
        }
        .navigationTitle("Organizer")
    }
}

struct OrganizerComparisonRowView: View {
    var row: OrganizerComparisonRow

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(row.name)
                    .font(.headline)
                Spacer()
                Text("\(row.fitScore)%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.questPrimary)
            }
            TagCloud(tags: [row.size, row.mode, row.availability, row.roles])
            if !row.notes.isEmpty {
                Text(row.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FeedbackHistoryView: View {
    @EnvironmentObject private var store: QuestBondStore

    var body: some View {
        List {
            if store.feedback.isEmpty {
                ContentUnavailableView("No feedback yet", systemImage: "checklist", description: Text("After a session, save private fit notes from the chat menu."))
            } else {
                ForEach(store.feedback) { feedback in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(feedback.sentiment.label)
                            .font(.headline)
                        Text(feedback.wouldPlayAgain ? "Would play again" : "Would not play again")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if !feedback.notes.isEmpty {
                            Text(feedback.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(feedback.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Feedback")
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let rows = rows(for: subviews, width: width)
        return CGSize(width: width, height: rows.reduce(CGFloat.zero) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> [(height: CGFloat, width: CGFloat)] {
        var rows: [(height: CGFloat, width: CGFloat)] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = currentWidth == 0 ? size.width : currentWidth + spacing + size.width

            if currentWidth > 0 && nextWidth > width {
                rows.append((currentHeight, currentWidth))
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentWidth = nextWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        if currentWidth > 0 {
            rows.append((currentHeight, currentWidth))
        }

        return rows
    }
}
