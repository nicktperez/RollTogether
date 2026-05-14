const STORAGE_KEY = "questbond_state_v1";

const seedGroups = [
  {
    id: "group_ashenvault",
    name: "The Ashen Vault",
    mode: "online",
    location: "EST",
    openSlots: 2,
    campaignStyle: "story-heavy",
    tableExperience: "intermediate",
    lookingForPartySize: "duo",
    desiredExperience: "any",
    desiredRoles: ["healer", "face"],
    characterVibe: "High-drama heroes and morally grey support casters.",
    schedule: "Wednesdays 8 PM EST",
    about: "Long-form political fantasy campaign with character-focused arcs.",
    contact: "Discord: AshenDM#1142",
    createdAt: "2026-02-20T19:00:00.000Z"
  },
  {
    id: "group_sunmarket",
    name: "Sunmarket Delvers",
    mode: "in-person",
    location: "Austin, TX",
    openSlots: 3,
    campaignStyle: "heroic",
    tableExperience: "new",
    lookingForPartySize: "trio",
    desiredExperience: "new",
    desiredRoles: ["tank", "support"],
    characterVibe: "Classic fantasy party energy with big set-piece battles.",
    schedule: "Saturdays 2 PM CST",
    about: "Beginner-friendly in-person table focused on teamwork and exploration.",
    contact: "sunmarket.table@gmail.com",
    createdAt: "2026-02-21T17:30:00.000Z"
  },
  {
    id: "group_mirrorspine",
    name: "Mirrorspine Pact",
    mode: "hybrid",
    location: "Seattle, WA / PST",
    openSlots: 1,
    campaignStyle: "gritty",
    tableExperience: "veteran",
    lookingForPartySize: "single",
    desiredExperience: "veteran",
    desiredRoles: ["controller", "scout"],
    characterVibe: "Low-magic intrigue, stealth, and consequences.",
    schedule: "Sundays 6 PM PST",
    about: "Serious tone, difficult choices, and tactical encounters.",
    contact: "DM via Discord: mirrorspine",
    createdAt: "2026-02-22T22:45:00.000Z"
  }
];

const seedParties = [
  {
    id: "party_amberduo",
    name: "Amber Duo",
    partySize: 2,
    mode: "online",
    location: "CST / EST",
    experience: "intermediate",
    rolesCovered: ["tank", "damage"],
    lookingForCampaign: "story-heavy",
    lookingForExperience: "intermediate",
    vibe: "Paladin + bard duo who love roleplay and heists.",
    schedule: "Weekdays after 7 PM CST",
    about: "Reliable duo looking for a long campaign and strong table chemistry.",
    contact: "Discord: AmberDuo",
    createdAt: "2026-02-20T22:00:00.000Z"
  },
  {
    id: "party_silverrookie",
    name: "Silver Rookie",
    partySize: 1,
    mode: "in-person",
    location: "Austin, TX",
    experience: "new",
    rolesCovered: ["support"],
    lookingForCampaign: "heroic",
    lookingForExperience: "new",
    vibe: "Cleric player brand new to 5e and eager to learn.",
    schedule: "Saturday afternoons",
    about: "Looking for a welcoming table with patient players.",
    contact: "Email: silverrookie@example.com",
    createdAt: "2026-02-23T11:15:00.000Z"
  },
  {
    id: "party_nighttrio",
    name: "Nightglass Trio",
    partySize: 3,
    mode: "hybrid",
    location: "Seattle, WA",
    experience: "veteran",
    rolesCovered: ["scout", "controller", "face"],
    lookingForCampaign: "gritty",
    lookingForExperience: "veteran",
    vibe: "Stealth-heavy operators with tactical combat focus.",
    schedule: "Sundays after 5 PM PST",
    about: "Three veteran players seeking difficult encounters and meaningful choices.",
    contact: "Discord: Nightglass",
    createdAt: "2026-02-24T16:20:00.000Z"
  },
  {
    id: "party_chaossquad",
    name: "Chaos Squad",
    partySize: 4,
    mode: "online",
    location: "US Time Zones",
    experience: "intermediate",
    rolesCovered: ["tank", "healer", "damage", "face"],
    lookingForCampaign: "comedy",
    lookingForExperience: "any",
    vibe: "Light-hearted improvisers who still show up prepared.",
    schedule: "Fridays 9 PM EST",
    about: "Looking for a DM that enjoys big personalities and creative plans.",
    contact: "Discord: chaos.squad",
    createdAt: "2026-02-24T23:05:00.000Z"
  }
];

const elements = {
  tabs: document.querySelectorAll(".tab"),
  panels: document.querySelectorAll(".panel"),

  groupCount: document.getElementById("group-count"),
  partyCount: document.getElementById("party-count"),
  matchCount: document.getElementById("match-count"),

  groupOwnerSelect: document.getElementById("group-owner-select"),
  groupPreMode: document.getElementById("group-pre-mode"),
  groupPreExperience: document.getElementById("group-pre-experience"),
  groupPreMinSize: document.getElementById("group-pre-min-size"),
  groupPreApply: document.getElementById("group-pre-apply"),
  groupPostMode: document.getElementById("group-post-mode"),
  groupPostCampaign: document.getElementById("group-post-campaign"),
  groupPostQuery: document.getElementById("group-post-query"),
  groupPostReset: document.getElementById("group-post-reset"),
  groupCard: document.getElementById("group-candidate-card"),
  groupCounter: document.getElementById("group-counter"),
  groupPassBtn: document.getElementById("group-pass-btn"),
  groupConnectBtn: document.getElementById("group-connect-btn"),

  partyOwnerSelect: document.getElementById("party-owner-select"),
  partyPreMode: document.getElementById("party-pre-mode"),
  partyPreCampaign: document.getElementById("party-pre-campaign"),
  partyPreMinSlots: document.getElementById("party-pre-min-slots"),
  partyPreApply: document.getElementById("party-pre-apply"),
  partyPostMode: document.getElementById("party-post-mode"),
  partyPostExperience: document.getElementById("party-post-experience"),
  partyPostQuery: document.getElementById("party-post-query"),
  partyPostReset: document.getElementById("party-post-reset"),
  partyCard: document.getElementById("party-candidate-card"),
  partyCounter: document.getElementById("party-counter"),
  partyPassBtn: document.getElementById("party-pass-btn"),
  partyConnectBtn: document.getElementById("party-connect-btn"),

  groupForm: document.getElementById("group-form"),
  partyForm: document.getElementById("party-form"),

  groupListings: document.getElementById("group-listings"),
  partyListings: document.getElementById("party-listings"),
  matchesList: document.getElementById("matches-list"),
  clearMatchesBtn: document.getElementById("clear-matches-btn")
};

let state = loadState();

init();

function init() {
  bindTabs();
  bindDiscoverControls();
  bindForms();
  bindMatchControls();
  renderAll();
}

function createDefaultState() {
  return {
    groups: clone(seedGroups),
    parties: clone(seedParties),
    matches: [],
    decisions: [],
    discover: {
      groupView: {
        ownerId: seedGroups[0].id,
        pre: {
          mode: "any",
          experience: "any",
          minPartySize: 1
        },
        post: {
          mode: "any",
          campaign: "any",
          query: ""
        }
      },
      partyView: {
        ownerId: seedParties[0].id,
        pre: {
          mode: "any",
          campaign: "any",
          minOpenSlots: 1
        },
        post: {
          mode: "any",
          experience: "any",
          query: ""
        }
      }
    }
  };
}

function loadState() {
  const fallback = createDefaultState();

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      return fallback;
    }

    const parsed = JSON.parse(raw);
    const safe = {
      groups: Array.isArray(parsed.groups) && parsed.groups.length > 0 ? parsed.groups : fallback.groups,
      parties: Array.isArray(parsed.parties) && parsed.parties.length > 0 ? parsed.parties : fallback.parties,
      matches: Array.isArray(parsed.matches) ? parsed.matches : [],
      decisions: Array.isArray(parsed.decisions) ? parsed.decisions : [],
      discover: parsed.discover && typeof parsed.discover === "object" ? parsed.discover : fallback.discover
    };

    safe.discover.groupView = {
      ownerId: safe.discover.groupView && safe.discover.groupView.ownerId,
      pre: {
        mode:
          safe.discover.groupView && safe.discover.groupView.pre && safe.discover.groupView.pre.mode
            ? safe.discover.groupView.pre.mode
            : "any",
        experience:
          safe.discover.groupView && safe.discover.groupView.pre && safe.discover.groupView.pre.experience
            ? safe.discover.groupView.pre.experience
            : "any",
        minPartySize: clampInt(
          safe.discover.groupView && safe.discover.groupView.pre && safe.discover.groupView.pre.minPartySize,
          1,
          6,
          1
        )
      },
      post: {
        mode:
          safe.discover.groupView && safe.discover.groupView.post && safe.discover.groupView.post.mode
            ? safe.discover.groupView.post.mode
            : "any",
        campaign:
          safe.discover.groupView && safe.discover.groupView.post && safe.discover.groupView.post.campaign
            ? safe.discover.groupView.post.campaign
            : "any",
        query:
          safe.discover.groupView && safe.discover.groupView.post && safe.discover.groupView.post.query
            ? safe.discover.groupView.post.query
            : ""
      }
    };

    safe.discover.partyView = {
      ownerId: safe.discover.partyView && safe.discover.partyView.ownerId,
      pre: {
        mode:
          safe.discover.partyView && safe.discover.partyView.pre && safe.discover.partyView.pre.mode
            ? safe.discover.partyView.pre.mode
            : "any",
        campaign:
          safe.discover.partyView && safe.discover.partyView.pre && safe.discover.partyView.pre.campaign
            ? safe.discover.partyView.pre.campaign
            : "any",
        minOpenSlots: clampInt(
          safe.discover.partyView && safe.discover.partyView.pre && safe.discover.partyView.pre.minOpenSlots,
          1,
          8,
          1
        )
      },
      post: {
        mode:
          safe.discover.partyView && safe.discover.partyView.post && safe.discover.partyView.post.mode
            ? safe.discover.partyView.post.mode
            : "any",
        experience:
          safe.discover.partyView && safe.discover.partyView.post && safe.discover.partyView.post.experience
            ? safe.discover.partyView.post.experience
            : "any",
        query:
          safe.discover.partyView && safe.discover.partyView.post && safe.discover.partyView.post.query
            ? safe.discover.partyView.post.query
            : ""
      }
    };

    if (!safe.groups.some((group) => group.id === safe.discover.groupView.ownerId)) {
      safe.discover.groupView.ownerId = safe.groups[0] ? safe.groups[0].id : "";
    }

    if (!safe.parties.some((party) => party.id === safe.discover.partyView.ownerId)) {
      safe.discover.partyView.ownerId = safe.parties[0] ? safe.parties[0].id : "";
    }

    return safe;
  } catch (error) {
    return fallback;
  }
}

function saveState() {
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch (error) {
    // Ignore storage failures to keep app usable.
  }
}

function bindTabs() {
  elements.tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      const target = tab.dataset.tabTarget;

      elements.tabs.forEach((item) => item.classList.remove("active"));
      tab.classList.add("active");

      elements.panels.forEach((panel) => {
        panel.classList.toggle("active", panel.id === target);
      });
    });
  });
}

function bindDiscoverControls() {
  elements.groupOwnerSelect.addEventListener("change", (event) => {
    state.discover.groupView.ownerId = event.target.value;
    saveState();
    renderDiscover("groupView");
  });

  elements.partyOwnerSelect.addEventListener("change", (event) => {
    state.discover.partyView.ownerId = event.target.value;
    saveState();
    renderDiscover("partyView");
  });

  elements.groupPreApply.addEventListener("click", () => {
    state.discover.groupView.pre.mode = elements.groupPreMode.value;
    state.discover.groupView.pre.experience = elements.groupPreExperience.value;
    state.discover.groupView.pre.minPartySize = clampInt(elements.groupPreMinSize.value, 1, 6, 1);
    saveState();
    renderDiscover("groupView");
  });

  elements.partyPreApply.addEventListener("click", () => {
    state.discover.partyView.pre.mode = elements.partyPreMode.value;
    state.discover.partyView.pre.campaign = elements.partyPreCampaign.value;
    state.discover.partyView.pre.minOpenSlots = clampInt(elements.partyPreMinSlots.value, 1, 8, 1);
    saveState();
    renderDiscover("partyView");
  });

  elements.groupPostMode.addEventListener("change", () => {
    state.discover.groupView.post.mode = elements.groupPostMode.value;
    saveState();
    renderDiscover("groupView");
  });

  elements.groupPostCampaign.addEventListener("change", () => {
    state.discover.groupView.post.campaign = elements.groupPostCampaign.value;
    saveState();
    renderDiscover("groupView");
  });

  elements.groupPostQuery.addEventListener("input", () => {
    state.discover.groupView.post.query = elements.groupPostQuery.value;
    saveState();
    renderDiscover("groupView");
  });

  elements.partyPostMode.addEventListener("change", () => {
    state.discover.partyView.post.mode = elements.partyPostMode.value;
    saveState();
    renderDiscover("partyView");
  });

  elements.partyPostExperience.addEventListener("change", () => {
    state.discover.partyView.post.experience = elements.partyPostExperience.value;
    saveState();
    renderDiscover("partyView");
  });

  elements.partyPostQuery.addEventListener("input", () => {
    state.discover.partyView.post.query = elements.partyPostQuery.value;
    saveState();
    renderDiscover("partyView");
  });

  elements.groupPostReset.addEventListener("click", () => {
    state.discover.groupView.post = {
      mode: "any",
      campaign: "any",
      query: ""
    };
    saveState();
    syncDiscoverInputs();
    renderDiscover("groupView");
  });

  elements.partyPostReset.addEventListener("click", () => {
    state.discover.partyView.post = {
      mode: "any",
      experience: "any",
      query: ""
    };
    saveState();
    syncDiscoverInputs();
    renderDiscover("partyView");
  });

  elements.groupPassBtn.addEventListener("click", () => processSwipe("groupView", "pass"));
  elements.groupConnectBtn.addEventListener("click", () => processSwipe("groupView", "connect"));
  elements.partyPassBtn.addEventListener("click", () => processSwipe("partyView", "pass"));
  elements.partyConnectBtn.addEventListener("click", () => processSwipe("partyView", "connect"));
}

function bindForms() {
  elements.groupForm.addEventListener("submit", (event) => {
    event.preventDefault();

    const listing = {
      id: makeId("group"),
      name: readValue("group-name"),
      mode: readValue("group-mode"),
      location: readValue("group-location"),
      openSlots: clampInt(readValue("group-open-slots"), 1, 8, 1),
      campaignStyle: readValue("group-campaign-style"),
      tableExperience: readValue("group-table-experience"),
      lookingForPartySize: readValue("group-looking-party-size"),
      desiredExperience: readValue("group-desired-experience"),
      desiredRoles: readCheckedValues("group-desired-roles"),
      characterVibe: readValue("group-character-vibe"),
      schedule: readValue("group-schedule"),
      about: readValue("group-about"),
      contact: readValue("group-contact"),
      createdAt: new Date().toISOString()
    };

    state.groups.unshift(listing);
    state.discover.groupView.ownerId = listing.id;

    saveState();
    event.target.reset();
    renderAll();
  });

  elements.partyForm.addEventListener("submit", (event) => {
    event.preventDefault();

    const listing = {
      id: makeId("party"),
      name: readValue("party-name"),
      partySize: clampInt(readValue("party-size"), 1, 6, 1),
      mode: readValue("party-mode"),
      location: readValue("party-location"),
      experience: readValue("party-experience"),
      rolesCovered: readCheckedValues("party-roles-covered"),
      lookingForCampaign: readValue("party-looking-campaign"),
      lookingForExperience: readValue("party-looking-experience"),
      vibe: readValue("party-vibe"),
      schedule: readValue("party-schedule"),
      about: readValue("party-about"),
      contact: readValue("party-contact"),
      createdAt: new Date().toISOString()
    };

    state.parties.unshift(listing);
    state.discover.partyView.ownerId = listing.id;

    saveState();
    event.target.reset();
    renderAll();
  });
}

function bindMatchControls() {
  elements.clearMatchesBtn.addEventListener("click", () => {
    state.matches = [];
    saveState();
    renderStats();
    renderMatches();
  });
}

function renderAll() {
  renderOwnerSelects();
  syncDiscoverInputs();
  renderStats();
  renderListings();
  renderDiscover("groupView");
  renderDiscover("partyView");
  renderMatches();
}

function renderOwnerSelects() {
  state.discover.groupView.ownerId = populateOwnerSelect(
    elements.groupOwnerSelect,
    state.groups,
    state.discover.groupView.ownerId,
    "No groups yet"
  );

  state.discover.partyView.ownerId = populateOwnerSelect(
    elements.partyOwnerSelect,
    state.parties,
    state.discover.partyView.ownerId,
    "No parties yet"
  );
}

function populateOwnerSelect(selectElement, list, selectedId, emptyLabel) {
  if (!list.length) {
    selectElement.innerHTML = `<option value="">${emptyLabel}</option>`;
    selectElement.disabled = true;
    return "";
  }

  selectElement.disabled = false;

  const nextSelectedId = list.some((item) => item.id === selectedId) ? selectedId : list[0].id;
  selectElement.innerHTML = list
    .map((item) => `<option value="${escapeAttribute(item.id)}">${escapeHtml(item.name)}</option>`)
    .join("");
  selectElement.value = nextSelectedId;

  return nextSelectedId;
}

function syncDiscoverInputs() {
  elements.groupPreMode.value = state.discover.groupView.pre.mode;
  elements.groupPreExperience.value = state.discover.groupView.pre.experience;
  elements.groupPreMinSize.value = state.discover.groupView.pre.minPartySize;

  elements.groupPostMode.value = state.discover.groupView.post.mode;
  elements.groupPostCampaign.value = state.discover.groupView.post.campaign;
  elements.groupPostQuery.value = state.discover.groupView.post.query;

  elements.partyPreMode.value = state.discover.partyView.pre.mode;
  elements.partyPreCampaign.value = state.discover.partyView.pre.campaign;
  elements.partyPreMinSlots.value = state.discover.partyView.pre.minOpenSlots;

  elements.partyPostMode.value = state.discover.partyView.post.mode;
  elements.partyPostExperience.value = state.discover.partyView.post.experience;
  elements.partyPostQuery.value = state.discover.partyView.post.query;
}

function renderDiscover(view) {
  if (view === "groupView") {
    const owner = getGroupOwner();
    const candidates = getGroupViewCandidates();

    if (!owner) {
      elements.groupCard.innerHTML = renderEmptyCard(
        "No group listing available.",
        "Create a group listing to start swiping through player parties."
      );
      elements.groupCounter.textContent = "0 candidates";
      elements.groupPassBtn.disabled = true;
      elements.groupConnectBtn.disabled = true;
      return;
    }

    if (!candidates.length) {
      elements.groupCard.innerHTML = renderEmptyCard(
        "No parties match your filters.",
        "Adjust pre-search or post-search filters, or publish more party listings."
      );
      elements.groupCounter.textContent = "0 candidates";
      elements.groupPassBtn.disabled = true;
      elements.groupConnectBtn.disabled = true;
      return;
    }

    const top = candidates[0];
    elements.groupCard.innerHTML = renderPartyCandidateCard(top);
    elements.groupCounter.textContent = `${candidates.length} candidate${candidates.length === 1 ? "" : "s"} available`;
    elements.groupPassBtn.disabled = false;
    elements.groupConnectBtn.disabled = false;
    return;
  }

  const owner = getPartyOwner();
  const candidates = getPartyViewCandidates();

  if (!owner) {
    elements.partyCard.innerHTML = renderEmptyCard(
      "No party listing available.",
      "Create a player/party listing to start swiping through groups."
    );
    elements.partyCounter.textContent = "0 candidates";
    elements.partyPassBtn.disabled = true;
    elements.partyConnectBtn.disabled = true;
    return;
  }

  if (!candidates.length) {
    elements.partyCard.innerHTML = renderEmptyCard(
      "No groups match your filters.",
      "Adjust pre-search or post-search filters, or publish more group listings."
    );
    elements.partyCounter.textContent = "0 candidates";
    elements.partyPassBtn.disabled = true;
    elements.partyConnectBtn.disabled = true;
    return;
  }

  const top = candidates[0];
  elements.partyCard.innerHTML = renderGroupCandidateCard(top);
  elements.partyCounter.textContent = `${candidates.length} candidate${candidates.length === 1 ? "" : "s"} available`;
  elements.partyPassBtn.disabled = false;
  elements.partyConnectBtn.disabled = false;
}

function renderPartyCandidateCard(candidate) {
  const party = candidate.entry;

  return `
    <div class="swipe-head">
      <div>
        <h3 class="swipe-title">${escapeHtml(party.name)}</h3>
        <p class="meta-line">${partySizeLabel(party.partySize)} (${party.partySize}) · ${modeLabel(party.mode)} · ${titleCase(
    party.experience
  )}</p>
      </div>
      <span class="score">Fit ${candidate.score}%</span>
    </div>
    <div class="badges">
      ${renderBadges([
        `Looking for: ${labelOrAny(party.lookingForCampaign)}`,
        `Schedule: ${party.schedule || "Flexible"}`,
        `Location: ${party.location || "No preference"}`,
        `Roles: ${party.rolesCovered.length ? party.rolesCovered.join(", ") : "Not listed"}`
      ])}
    </div>
    <p class="meta-line">${escapeHtml(party.vibe || "No character vibe provided.")}</p>
    <p class="meta-line">${escapeHtml(party.about || "No summary provided.")}</p>
    <ul class="reason-list">${candidate.reasons.map((reason) => `<li>${escapeHtml(reason)}</li>`).join("")}</ul>
    <p class="meta-line">Contact: ${escapeHtml(party.contact || "Not provided")}</p>
  `;
}

function renderGroupCandidateCard(candidate) {
  const group = candidate.entry;

  return `
    <div class="swipe-head">
      <div>
        <h3 class="swipe-title">${escapeHtml(group.name)}</h3>
        <p class="meta-line">${modeLabel(group.mode)} · ${titleCase(group.campaignStyle)} · ${group.openSlots} open slot${
    group.openSlots === 1 ? "" : "s"
  }</p>
      </div>
      <span class="score">Fit ${candidate.score}%</span>
    </div>
    <div class="badges">
      ${renderBadges([
        `Table level: ${titleCase(group.tableExperience)}`,
        `Wants: ${labelOrAny(group.lookingForPartySize)}`,
        `Schedule: ${group.schedule || "Flexible"}`,
        `Location: ${group.location || "No preference"}`,
        `Desired roles: ${group.desiredRoles.length ? group.desiredRoles.join(", ") : "Any"}`
      ])}
    </div>
    <p class="meta-line">${escapeHtml(group.characterVibe || "No specific character vibe listed.")}</p>
    <p class="meta-line">${escapeHtml(group.about || "No table summary provided.")}</p>
    <ul class="reason-list">${candidate.reasons.map((reason) => `<li>${escapeHtml(reason)}</li>`).join("")}</ul>
    <p class="meta-line">Contact: ${escapeHtml(group.contact || "Not provided")}</p>
  `;
}

function renderEmptyCard(title, message) {
  return `
    <h3 class="swipe-title">${escapeHtml(title)}</h3>
    <p class="meta-line">${escapeHtml(message)}</p>
  `;
}

function renderListings() {
  if (!state.groups.length) {
    elements.groupListings.innerHTML = `<p class="empty-state">No group listings yet.</p>`;
  } else {
    elements.groupListings.innerHTML = state.groups
      .map((group) => {
        return `
          <article class="listing-item">
            <h3>${escapeHtml(group.name)}</h3>
            <p>${modeLabel(group.mode)} · ${group.openSlots} open slot${group.openSlots === 1 ? "" : "s"} · ${titleCase(
          group.campaignStyle
        )}</p>
            <div class="badges">
              ${renderBadges([
                `Wants: ${labelOrAny(group.lookingForPartySize)}`,
                `Player level: ${labelOrAny(group.desiredExperience)}`,
                `Location: ${group.location || "No preference"}`,
                `Schedule: ${group.schedule || "Flexible"}`
              ])}
            </div>
            <p>${escapeHtml(group.about || "No summary provided.")}</p>
          </article>
        `;
      })
      .join("");
  }

  if (!state.parties.length) {
    elements.partyListings.innerHTML = `<p class="empty-state">No player/party listings yet.</p>`;
  } else {
    elements.partyListings.innerHTML = state.parties
      .map((party) => {
        return `
          <article class="listing-item">
            <h3>${escapeHtml(party.name)}</h3>
            <p>${partySizeLabel(party.partySize)} (${party.partySize}) · ${modeLabel(party.mode)} · ${titleCase(
          party.experience
        )}</p>
            <div class="badges">
              ${renderBadges([
                `Looking for: ${labelOrAny(party.lookingForCampaign)}`,
                `Table level: ${labelOrAny(party.lookingForExperience)}`,
                `Location: ${party.location || "No preference"}`,
                `Schedule: ${party.schedule || "Flexible"}`
              ])}
            </div>
            <p>${escapeHtml(party.about || "No summary provided.")}</p>
          </article>
        `;
      })
      .join("");
  }
}

function renderMatches() {
  if (!state.matches.length) {
    elements.matchesList.innerHTML = `<p class="empty-state">No saved connections yet.</p>`;
    return;
  }

  elements.matchesList.innerHTML = state.matches
    .slice()
    .sort((a, b) => toTime(b.connectedAt) - toTime(a.connectedAt))
    .map((match) => {
      return `
        <article class="listing-item">
          <h3>${escapeHtml(match.groupName)} <span aria-hidden="true">x</span> ${escapeHtml(match.partyName)}</h3>
          <p>Connected ${escapeHtml(formatDate(match.connectedAt))} · Score ${escapeHtml(String(match.score))}% · Initiated by ${escapeHtml(
        match.initiatedBy
      )}</p>
        </article>
      `;
    })
    .join("");
}

function renderStats() {
  elements.groupCount.textContent = String(state.groups.length);
  elements.partyCount.textContent = String(state.parties.length);
  elements.matchCount.textContent = String(state.matches.length);
}

function getGroupViewCandidates() {
  const owner = getGroupOwner();
  if (!owner) {
    return [];
  }

  const pre = state.discover.groupView.pre;
  const post = state.discover.groupView.post;

  return state.parties
    .filter((party) => !hasDecision("groupView", owner.id, party.id))
    .filter((party) => matchesModeFilter(party.mode, pre.mode))
    .filter((party) => valueMatches(pre.experience, party.experience))
    .filter((party) => party.partySize >= pre.minPartySize)
    .map((party) => {
      const scored = scoreGroupToParty(owner, party);
      return {
        entry: party,
        score: scored.score,
        reasons: scored.reasons
      };
    })
    .filter((candidate) => matchesModeFilter(candidate.entry.mode, post.mode))
    .filter((candidate) => post.campaign === "any" || candidate.entry.lookingForCampaign === "any" || candidate.entry.lookingForCampaign === post.campaign)
    .filter((candidate) => matchesQuery(candidate.entry, post.query, ["name", "location", "vibe", "about"]))
    .sort((a, b) => b.score - a.score || toTime(b.entry.createdAt) - toTime(a.entry.createdAt));
}

function getPartyViewCandidates() {
  const owner = getPartyOwner();
  if (!owner) {
    return [];
  }

  const pre = state.discover.partyView.pre;
  const post = state.discover.partyView.post;

  return state.groups
    .filter((group) => !hasDecision("partyView", owner.id, group.id))
    .filter((group) => matchesModeFilter(group.mode, pre.mode))
    .filter((group) => pre.campaign === "any" || group.campaignStyle === pre.campaign)
    .filter((group) => group.openSlots >= pre.minOpenSlots)
    .map((group) => {
      const scored = scorePartyToGroup(owner, group);
      return {
        entry: group,
        score: scored.score,
        reasons: scored.reasons
      };
    })
    .filter((candidate) => matchesModeFilter(candidate.entry.mode, post.mode))
    .filter((candidate) => valueMatches(post.experience, candidate.entry.tableExperience))
    .filter((candidate) => matchesQuery(candidate.entry, post.query, ["name", "location", "characterVibe", "about"]))
    .sort((a, b) => b.score - a.score || toTime(b.entry.createdAt) - toTime(a.entry.createdAt));
}

function processSwipe(view, decision) {
  const owner = view === "groupView" ? getGroupOwner() : getPartyOwner();
  if (!owner) {
    return;
  }

  const candidates = view === "groupView" ? getGroupViewCandidates() : getPartyViewCandidates();
  if (!candidates.length) {
    return;
  }

  const target = candidates[0].entry;

  state.decisions.push({
    id: makeId("decision"),
    view,
    ownerId: owner.id,
    targetId: target.id,
    decision,
    createdAt: new Date().toISOString()
  });

  if (decision === "connect") {
    const pair =
      view === "groupView"
        ? {
            groupId: owner.id,
            groupName: owner.name,
            partyId: target.id,
            partyName: target.name,
            score: candidates[0].score,
            initiatedBy: "group"
          }
        : {
            groupId: target.id,
            groupName: target.name,
            partyId: owner.id,
            partyName: owner.name,
            score: candidates[0].score,
            initiatedBy: "party"
          };

    const exists = state.matches.some((match) => match.groupId === pair.groupId && match.partyId === pair.partyId);

    if (!exists) {
      state.matches.unshift({
        id: makeId("match"),
        groupId: pair.groupId,
        groupName: pair.groupName,
        partyId: pair.partyId,
        partyName: pair.partyName,
        score: pair.score,
        initiatedBy: pair.initiatedBy,
        connectedAt: new Date().toISOString()
      });
    }
  }

  saveState();
  renderAll();
}

function getGroupOwner() {
  return state.groups.find((group) => group.id === state.discover.groupView.ownerId) || null;
}

function getPartyOwner() {
  return state.parties.find((party) => party.id === state.discover.partyView.ownerId) || null;
}

function hasDecision(view, ownerId, targetId) {
  return state.decisions.some(
    (decision) => decision.view === view && decision.ownerId === ownerId && decision.targetId === targetId
  );
}

function scoreGroupToParty(group, party) {
  let score = 0;
  const reasons = [];

  if (areModesCompatible(group.mode, party.mode)) {
    score += 20;
    reasons.push("Session type alignment is strong.");
  } else {
    reasons.push("Session type preference conflicts.");
  }

  const slotPoints = capacityPoints(group.openSlots, party.partySize, 20);
  score += slotPoints;
  reasons.push(
    slotPoints > 0
      ? `Your ${group.openSlots} open slot${group.openSlots === 1 ? "" : "s"} fit this ${partySizeLabel(party.partySize).toLowerCase()}.`
      : "Party size is currently larger than your open slots."
  );

  if (valueMatches(group.desiredExperience, party.experience)) {
    score += 15;
    reasons.push("Experience level fits what your group wants.");
  }

  const roleFit = roleCompatibility(group.desiredRoles, party.rolesCovered, 20);
  score += roleFit.points;
  reasons.push(roleFit.reason);

  if (party.lookingForCampaign === "any" || party.lookingForCampaign === group.campaignStyle) {
    score += 15;
    reasons.push("Campaign style preference lines up.");
  }

  if (partySizeMatch(group.lookingForPartySize, party.partySize)) {
    score += 10;
    reasons.push("Party size category matches your target.");
  }

  return {
    score: clampInt(Math.round(score), 0, 100, 0),
    reasons: reasons.slice(0, 4)
  };
}

function scorePartyToGroup(party, group) {
  let score = 0;
  const reasons = [];

  if (areModesCompatible(party.mode, group.mode)) {
    score += 20;
    reasons.push("Session type alignment is strong.");
  } else {
    reasons.push("Session type preference conflicts.");
  }

  const slotPoints = capacityPoints(group.openSlots, party.partySize, 20);
  score += slotPoints;
  reasons.push(
    slotPoints > 0
      ? `Group has enough room (${group.openSlots} slot${group.openSlots === 1 ? "" : "s"}) for your party.`
      : "Group may not have enough room for your party size."
  );

  if (valueMatches(party.lookingForExperience, group.tableExperience)) {
    score += 15;
    reasons.push("Table experience level matches your preference.");
  }

  const roleFit = roleCompatibility(group.desiredRoles, party.rolesCovered, 20);
  score += roleFit.points;
  reasons.push(roleFit.reason);

  if (party.lookingForCampaign === "any" || party.lookingForCampaign === group.campaignStyle) {
    score += 15;
    reasons.push("Campaign style preference lines up.");
  }

  if (partySizeMatch(group.lookingForPartySize, party.partySize)) {
    score += 10;
    reasons.push("Your party size is what this group requested.");
  }

  return {
    score: clampInt(Math.round(score), 0, 100, 0),
    reasons: reasons.slice(0, 4)
  };
}

function roleCompatibility(wantedRoles, offeredRoles, weight) {
  if (!wantedRoles.length) {
    return {
      points: weight,
      reason: "Group accepts any role composition."
    };
  }

  if (!offeredRoles.length) {
    return {
      points: 0,
      reason: "Role overlap is unknown because no roles were listed."
    };
  }

  const overlap = offeredRoles.filter((role) => wantedRoles.includes(role));
  const ratio = overlap.length / wantedRoles.length;

  if (overlap.length === 0) {
    return {
      points: 0,
      reason: "No direct role overlap with requested composition."
    };
  }

  return {
    points: Math.round(weight * ratio),
    reason: `Role overlap: ${overlap.join(", ")}.`
  };
}

function capacityPoints(openSlots, partySize, weight) {
  if (openSlots >= partySize) {
    return weight;
  }

  if (openSlots + 1 === partySize) {
    return Math.round(weight * 0.45);
  }

  return 0;
}

function partySizeMatch(targetSize, partySize) {
  if (targetSize === "any") {
    return true;
  }

  return targetSize === partySizeCategory(partySize);
}

function partySizeCategory(size) {
  if (size <= 1) {
    return "single";
  }
  if (size === 2) {
    return "duo";
  }
  if (size === 3) {
    return "trio";
  }
  return "squad";
}

function partySizeLabel(size) {
  const category = partySizeCategory(size);
  if (category === "single") {
    return "Single";
  }
  if (category === "duo") {
    return "Duo";
  }
  if (category === "trio") {
    return "Trio";
  }
  return "Squad";
}

function valueMatches(requested, actual) {
  return requested === "any" || actual === "any" || requested === actual;
}

function areModesCompatible(left, right) {
  if (left === right) {
    return true;
  }

  if (left === "hybrid") {
    return right === "online" || right === "in-person" || right === "hybrid";
  }

  if (right === "hybrid") {
    return left === "online" || left === "in-person" || left === "hybrid";
  }

  return false;
}

function matchesModeFilter(mode, filterMode) {
  if (filterMode === "any") {
    return true;
  }

  if (mode === filterMode) {
    return true;
  }

  if (mode === "hybrid" && (filterMode === "online" || filterMode === "in-person")) {
    return true;
  }

  return false;
}

function matchesQuery(entry, query, keys) {
  const trimmed = (query || "").trim().toLowerCase();
  if (!trimmed) {
    return true;
  }

  return keys.some((key) => {
    const value = entry[key];
    return typeof value === "string" && value.toLowerCase().includes(trimmed);
  });
}

function renderBadges(values) {
  return values
    .filter(Boolean)
    .map((value) => `<span class="badge">${escapeHtml(value)}</span>`)
    .join("");
}

function labelOrAny(value) {
  if (!value) {
    return "Any";
  }

  return titleCase(value);
}

function modeLabel(mode) {
  if (mode === "in-person") {
    return "In-Person";
  }
  if (mode === "online") {
    return "Online";
  }
  if (mode === "hybrid") {
    return "Hybrid";
  }
  return "Any";
}

function titleCase(value) {
  if (!value) {
    return "Any";
  }

  return value
    .split("-")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join("-");
}

function formatDate(isoValue) {
  const date = new Date(isoValue);
  if (Number.isNaN(date.getTime())) {
    return "Unknown time";
  }

  return date.toLocaleString();
}

function toTime(value) {
  const date = new Date(value);
  const timestamp = date.getTime();
  return Number.isNaN(timestamp) ? 0 : timestamp;
}

function readCheckedValues(name) {
  return Array.from(document.querySelectorAll(`input[name="${name}"]:checked`)).map((input) => input.value);
}

function readValue(id) {
  const element = document.getElementById(id);
  if (!element) {
    return "";
  }

  return typeof element.value === "string" ? element.value.trim() : "";
}

function clampInt(value, min, max, fallback) {
  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed)) {
    return fallback;
  }

  return Math.max(min, Math.min(max, parsed));
}

function makeId(prefix) {
  return `${prefix}_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`;
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function escapeAttribute(value) {
  return escapeHtml(value).replaceAll("`", "");
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}
