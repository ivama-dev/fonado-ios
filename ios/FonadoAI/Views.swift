import Contacts
import ContactsUI
import SwiftUI

enum FonadoStyle {
    // The green action fill is paired with anthracite; link/tint colors retain
    // readable contrast in each appearance while using the supplied palette.
    static let accent = Color("AccentColor")
    static let green = Color(red: 150 / 255, green: 185 / 255, blue: 20 / 255)
    static let yellowGreen = Color(red: 200 / 255, green: 215 / 255, blue: 65 / 255)
    static let anthracite = Color(red: 55 / 255, green: 55 / 255, blue: 55 / 255)
    static let ink = Color("BrandInk")
    static let background = Color("BrandBackground")
    static let surface = Color("BrandSurface")
    static let brandGradient = LinearGradient(colors: [ink, ink], startPoint: .top, endPoint: .bottom)
    static let actionGradient = LinearGradient(colors: [green, green], startPoint: .top, endPoint: .bottom)
    static let softGradient = LinearGradient(colors: [accent.opacity(0.07), accent.opacity(0.11)], startPoint: .topLeading, endPoint: .bottomTrailing)

    /// Custom fonts scale with the matching Dynamic Type text style.
    static func font(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> Font {
        let size: CGFloat
        let defaultWeight: Font.Weight
        switch style {
        case .largeTitle: (size, defaultWeight) = (34, .bold)
        case .title: (size, defaultWeight) = (28, .bold)
        case .title2: (size, defaultWeight) = (22, .semibold)
        case .title3: (size, defaultWeight) = (20, .semibold)
        case .headline: (size, defaultWeight) = (17, .semibold)
        case .subheadline: (size, defaultWeight) = (15, .regular)
        case .callout: (size, defaultWeight) = (16, .regular)
        case .footnote: (size, defaultWeight) = (13, .regular)
        case .caption: (size, defaultWeight) = (12, .regular)
        case .caption2: (size, defaultWeight) = (11, .regular)
        default: (size, defaultWeight) = (17, .regular)
        }
        return font(size: size, weight: weight ?? defaultWeight, relativeTo: style)
    }

    static func font(size: CGFloat, weight: Font.Weight = .regular,
                     relativeTo style: Font.TextStyle = .body) -> Font {
        let name: String
        if weight == .bold || weight == .heavy || weight == .black { name = "Manrope-Bold" }
        else if weight == .semibold || weight == .medium { name = "Manrope-SemiBold" }
        else { name = "Manrope-Regular" }
        return .custom(name, size: size, relativeTo: style)
    }
}

/// Original Fonado.AI vector wordmark, scaled uniformly with appearance variants.
struct FonadoWordmark: View {
    var width: CGFloat = 160
    var body: some View {
        Image("FonadoLogo")
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width * 500 / 1600)
            .accessibilityLabel("Fonado")
    }
}

/// The wordmark is decoration, so it does not share the controls' glass capsule.
struct FonadoBrandToolbar: ToolbarContent {
    @ToolbarContentBuilder
    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) { FonadoWordmark() }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) { FonadoWordmark() }
        }
    }
}

struct FonadoCallButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? FonadoStyle.anthracite : FonadoStyle.ink.opacity(0.45))
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(isEnabled ? AnyShapeStyle(FonadoStyle.actionGradient) : AnyShapeStyle(FonadoStyle.accent.opacity(0.10)))
            }
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

enum HomeTab: String, CaseIterable, Identifiable {
    case favorites = "Favoriten", recents = "Anrufliste", keypad = "Wählen", contacts = "Kontakte", team = "Team"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .favorites: "star.fill"; case .recents: "clock"; case .keypad: "circle.grid.3x3.fill"; case .contacts: "person.crop.rectangle.stack"; case .team: "person.2.fill" }
    }
}

struct RootView: View {
    @EnvironmentObject private var phone: PhoneStore
    @AppStorage("fonado.startTab") private var startTab = HomeTab.favorites.rawValue
    @State private var tab = HomeTab.favorites
    @State private var settings = false
    @State private var didChooseStart = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $tab) {
            ForEach(HomeTab.allCases) { destination in
                NavigationStack {
                    Group {
                        switch destination {
                        case .favorites: FavoritesView()
                        case .recents: RecentsView()
                        case .keypad: DialpadView()
                        case .contacts: ContactsTabView()
                        case .team: TeamView()
                        }
                    }
                    .background(FonadoStyle.background)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(destination.rawValue)
                                .font(FonadoStyle.font(.largeTitle, weight: .bold))
                                .accessibilityAddTraits(.isHeader)
                            Text(phone.registration.label + " · " + phone.networkLabel)
                                .font(FonadoStyle.font(.caption, weight: .medium)).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(FonadoStyle.background)
                    }
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        FonadoBrandToolbar()
                        ToolbarItem(placement: .topBarTrailing) {
                            AvailabilityProfileMenu()
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { phone.sheetOpened("settings"); settings = true } label: {
                                Label("Einstellungen", systemImage: "gearshape")
                            }
                            .accessibilityHint("Konto, Anrufprofile und weitere Einstellungen öffnen")
                        }
                    }
                }
                .tabItem { Label(destination.rawValue, systemImage: destination.symbol) }
                .tag(destination)
            }
        }
        .overlay(alignment: .bottom) {
            if let notice = phone.notice, phone.call == nil {
                Button { phone.clearNotice() } label: {
                    Text(notice).font(FonadoStyle.font(.footnote)).padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }.padding(.bottom, 65).padding(.horizontal)
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active: phone.becameActive()
            case .inactive: phone.becameInactive(background: false)
            case .background: phone.becameInactive(background: true)
            @unknown default: break
            }
        }
        .sheet(isPresented: $settings, onDismiss: { phone.sheetClosed("settings") }) { SettingsView() }
        .onChange(of: phone.call?.id) { _, id in if id != nil { settings = false } }
        .fullScreenCover(isPresented: Binding(get: { phone.call != nil && phone.presentedSheets.isEmpty }, set: { if !$0 { phone.end() } })) {
            CallView()
        }
        .onAppear {
            guard !didChooseStart else { return }
            #if DEBUG
            if TeamPreview.enabled { tab = .team; didChooseStart = true; return }
            #endif
            let desired = HomeTab(rawValue: startTab) ?? .favorites
            tab = desired == .favorites && phone.favorites.isEmpty && phone.favoriteGroups.count == 1 ? .keypad : desired
            didChooseStart = true
        }
        .onChange(of: phone.favorites.isEmpty) { _, empty in
            if empty && phone.favoriteGroups.count == 1 && tab == .favorites { tab = .keypad }
        }
    }
}

struct Avatar: View {
    @EnvironmentObject private var customer: CustomerAccount
    let contact: Contact
    var large = false
    var body: some View {
        ProfilePortrait(thumbnail: customer.presenceMember(for: contact)?.picture,
                        initials: contact.initials, size: large ? 88 : 48)
    }
}

struct FavoritesView: View {
    @EnvironmentObject private var phone: PhoneStore
    @EnvironmentObject private var customer: CustomerAccount
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @StateObject private var directory = ContactsDirectory()
    @State private var query = ""
    @State private var searching = false
    @State private var edit = false
    @State private var selected: DeviceContact?

    private var showingSearch: Bool { searching || !query.isEmpty }
    private var shouldLoadContacts: Bool { showingSearch && scenePhase == .active && phone.call == nil && !edit }
    private var matches: [Contact] {
        phone.favorites.filter { contact in
            DeviceContact(id: contact.id, name: contact.name + " " + contact.role,
                          numbers: [DevicePhoneNumber(id: contact.id, label: contact.role, value: contact.number)])
                .matches(query)
        }
    }
    private var localMatches: [DeviceContact] { directory.contacts.filter { $0.matches(query) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if showingSearch {
                    searchResults
                } else {
                    HStack {
                        Text("Deine Kurzwahl").font(FonadoStyle.font(.subheadline)).foregroundStyle(.secondary)
                        Spacer()
                        Button("Bearbeiten") { phone.sheetOpened("favorites"); edit = true }.font(FonadoStyle.font(.subheadline))
                    }
                    if matches.isEmpty && phone.favoriteGroups.count == 1 {
                        ContentUnavailableView(query.isEmpty ? "Deine Favoriten" : "Kein Kontakt gefunden", systemImage: "star", description: Text("Öffne Kontakte oder suche hier nach einem Namen. Mit dem Stern speicherst du eine Rufnummer als Favorit."))
                    }
                    ForEach(phone.favoriteGroups) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.name).font(FonadoStyle.font(.title3, weight: .bold))
                            if group.contacts.isEmpty {
                                Text("Noch keine Favoriten in dieser Gruppe.").font(FonadoStyle.font(.caption)).foregroundStyle(.secondary)
                            } else { favoriteCards(group.contacts) }
                        }
                    }
                    FavoriteSyncNotice()
                    if let notice = phone.notice { Text(notice).font(FonadoStyle.font(.footnote)).foregroundStyle(.secondary) }
                }
            }.padding(20)
        }
        .searchable(text: $query, isPresented: $searching, placement: .navigationBarDrawer(displayMode: .always), prompt: "Name oder Nummer")
        .sheet(isPresented: $edit, onDismiss: { phone.sheetClosed("favorites") }) { FavoriteEditor() }
        .onChange(of: phone.call?.id) { _, id in if id != nil { edit = false; selected = nil } }
        .onChange(of: customer.signedIn) { _, signedIn in if !signedIn { edit = false; selected = nil } }
        .task(id: shouldLoadContacts) {
            if shouldLoadContacts { await directory.refresh() }
            else { directory.clear(); selected = nil }
        }
        .onReceive(NotificationCenter.default.publisher(for: .CNContactStoreDidChange)) { _ in
            selected = nil
            if shouldLoadContacts { Task { await directory.refresh() } }
        }
        .onDisappear { directory.clear() }
        .sheet(item: $selected) { person in
            DeviceContactNumbersView(person: person) { phone.start($0) }
        }
    }

    private func favoriteCards(_ contacts: [Contact]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
            ForEach(contacts) { contact in
                Button { phone.start(contact) } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .top) {
                            Avatar(contact: contact)
                            Spacer(minLength: 4)
                            Image(systemName: "phone").font(FonadoStyle.font(.subheadline)).foregroundStyle(FonadoStyle.accent)
                        }.padding(.bottom, 9)
                        Text(contact.name).font(FonadoStyle.font(.headline)).foregroundStyle(.primary)
                        Text("\(contact.role) · \(contact.number)").font(FonadoStyle.font(.caption)).foregroundStyle(.secondary)
                        if let member = customer.presenceMember(for:contact) { PresenceStatusView(userID:member.id) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(17)
                    .background(FonadoStyle.surface, in: RoundedRectangle(cornerRadius: 23))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(contact.name) anrufen, \(contact.role), \(contact.number)")
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if !matches.isEmpty {
            Text("Favoriten").font(FonadoStyle.font(.subheadline)).foregroundStyle(.secondary)
            LazyVStack(spacing: 8) {
                ForEach(matches) { contact in
                    Button { phone.start(contact) } label: {
                        HStack {
                            VStack(alignment:.leading,spacing:5) {
                                ContactLabel(contact: contact)
                                if let member = customer.presenceMember(for:contact) { PresenceStatusView(userID:member.id) }
                            }
                            Spacer()
                            Image(systemName: "phone").foregroundStyle(FonadoStyle.accent)
                        }.padding(12).background(FonadoStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                    .accessibilityLabel("\(contact.name), Favorit anrufen")
                }
            }
        }

        if directory.canRead {
            if directory.access == .limited {
                Text("Du durchsuchst deine freigegebenen iPhone-Kontakte.").font(FonadoStyle.font(.footnote)).foregroundStyle(.secondary)
                Button("Freigabe verwalten") { openContactSettings() }.font(FonadoStyle.font(.footnote))
            }
            if directory.isLoading {
                ProgressView("iPhone-Kontakte laden …")
            } else if let message = directory.errorMessage {
                Text(message).font(FonadoStyle.font(.subheadline)).foregroundStyle(.secondary)
                Button("Erneut versuchen") { Task { await directory.refresh() } }
            } else if !localMatches.isEmpty {
                Text("iPhone-Kontakte").font(FonadoStyle.font(.subheadline)).foregroundStyle(.secondary)
                LazyVStack(spacing: 8) {
                    ForEach(localMatches) { person in
                        HStack(spacing: 4) {
                        Button {
                            if person.numbers.count == 1, let number = person.numbers.first {
                                phone.start(person.callContact(for: number))
                            } else { selected = person }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle").font(FonadoStyle.font(.title)).foregroundStyle(FonadoStyle.accent)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(person.name).foregroundStyle(.primary)
                                    Text(person.numbers.count == 1 ? person.numbers[0].value : "\(person.numbers.count) Rufnummern")
                                        .font(FonadoStyle.font(.subheadline)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "phone").foregroundStyle(FonadoStyle.accent)
                            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                .background(FonadoStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                        }.buttonStyle(.plain)
                        .accessibilityLabel("\(person.name), \(person.numbers.count == 1 ? "Anruf starten" : "Rufnummer auswählen")")
                        DeviceContactFavoriteButton(person: person)
                        }
                    }
                }
            } else if matches.isEmpty {
                ContentUnavailableView("Kein Kontakt gefunden", systemImage: "magnifyingglass", description: Text("Suche nach einem Namen oder einem Teil der Telefonnummer."))
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Label("iPhone-Kontakte durchsuchen", systemImage: "person.crop.rectangle.stack").font(FonadoStyle.font(.headline))
                switch directory.access {
                case .notRequested:
                    Text("Gib deine Kontakte einmal frei. Danach findest du sie automatisch hier in der Suche.")
                        .font(FonadoStyle.font(.subheadline)).foregroundStyle(.secondary)
                    Button("Kontakte freigeben") { Task { await directory.requestAccess() } }.buttonStyle(.borderedProminent)
                case .denied:
                    Text("Erlaube den Kontaktzugriff in den iPhone-Einstellungen, um auch lokale Kontakte zu finden.")
                        .font(FonadoStyle.font(.subheadline)).foregroundStyle(.secondary)
                    Button("Einstellungen öffnen") { openContactSettings() }
                default:
                    Text("Der Kontaktzugriff ist durch die Geräteeinstellungen eingeschränkt.").font(FonadoStyle.font(.subheadline)).foregroundStyle(.secondary)
                }
                if let message = directory.errorMessage { Text(message).font(FonadoStyle.font(.footnote)).foregroundStyle(.secondary) }
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(FonadoStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func openContactSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}

struct FavoriteSyncNotice: View {
    @EnvironmentObject private var phone: PhoneStore
    @State private var importing = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !phone.favoriteSyncStatus.isEmpty { Text(phone.favoriteSyncStatus).font(FonadoStyle.font(.caption)).foregroundStyle(.secondary) }
            if phone.canImportLegacyFavorites {
                Button("Vorhandene Favoriten übernehmen") { importing = true }.font(FonadoStyle.font(.caption))
            }
        }
        .alert("Vorhandene Favoriten übernehmen?", isPresented: $importing) {
            Button("Übernehmen") { phone.importLegacyFavorites() }
            Button("Abbrechen", role: .cancel) {}
        } message: { Text("Auf diesem Gerät gibt es ältere Favoriten ohne bestätigte Kontozuordnung. Übernimm sie in das angemeldete Konto, wenn es deine eigenen Favoriten sind. Die ursprüngliche Datei bleibt erhalten.") }
    }
}

struct FavoriteEditor: View {
    @EnvironmentObject private var phone: PhoneStore
    @Environment(\.dismiss) private var dismiss
    @State private var mode = 0
    @State private var name = ""
    @State private var creating = false
    @State private var renaming = false
    @State private var deleting = false
    @State private var selectedGroup: FavoriteGroup?
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Bearbeiten", selection: $mode) {
                        Text("Gruppen").tag(0); Text("Favoriten").tag(1)
                    }.pickerStyle(.segmented)
                }
                if mode == 0 {
                    Section {
                        ForEach(phone.favoriteGroups) { group in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(group.name).font(FonadoStyle.font(.headline))
                                    Text("\(group.contacts.count) Favoriten").font(FonadoStyle.font(.caption)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if !group.isGeneral {
                                    Menu {
                                        Button("Umbenennen") { selectedGroup = group; name = group.name; renaming = true }
                                        Button("Gruppe löschen", role: .destructive) { selectedGroup = group; deleting = true }
                                    } label: { Image(systemName: "ellipsis") }
                                        .accessibilityLabel("Gruppe \(group.name) bearbeiten")
                                }
                            }
                        }.onMove { phone.moveFavoriteGroups(from: $0, to: $1) }
                    } header: { Text("Reihenfolge der Gruppen") }
                      footer: { Text("Ziehe die Gruppen am Griff nach oben oder unten. Beim Löschen einer Gruppe bleiben ihre Favoriten unter Allgemein erhalten.") }
                } else {
                    ForEach(phone.favoriteGroups) { group in
                        Section(group.name) {
                            ForEach(group.contacts) { contact in
                                HStack {
                                    ContactLabel(contact: contact)
                                    Spacer()
                                    Menu {
                                        ForEach(phone.favoriteGroups) { destination in
                                            Button(destination.name) { phone.assignFavorite(contact.id, to: destination.id) }
                                                .disabled(destination.id == group.id)
                                        }
                                        Divider()
                                        Button("Favorit entfernen", role: .destructive) { phone.toggleFavorite(contact) }
                                    } label: { Image(systemName: "folder") }
                                        .accessibilityLabel("\(contact.name) in eine andere Gruppe verschieben")
                                }
                            }.onMove { phone.moveFavorites(in: group.id, from: $0, to: $1) }
                            if group.contacts.isEmpty { Text("Noch keine Favoriten").foregroundStyle(.secondary) }
                        }
                    }
                }
                if let error = phone.favoriteEditingError { Section { Text(error).foregroundStyle(.red) } }
                Section { FavoriteSyncNotice() }
            }
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden).background(FonadoStyle.background)
            .navigationTitle("Favoriten bearbeiten").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { name = ""; creating = true } label: { Label("Neue Gruppe", systemImage: "folder.badge.plus") }
                }
                ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } }
            }
            .alert("Neue Gruppe", isPresented: $creating) {
                TextField("Gruppenname", text: $name)
                Button("Anlegen") { phone.createFavoriteGroup(name) }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Abbrechen", role: .cancel) {}
            }
            .alert("Gruppe umbenennen", isPresented: $renaming) {
                TextField("Gruppenname", text: $name)
                Button("Speichern") { if let group = selectedGroup { phone.renameFavoriteGroup(group.id, name: name) } }
                Button("Abbrechen", role: .cancel) {}
            }
            .alert("Gruppe löschen?", isPresented: $deleting) {
                Button("Löschen", role: .destructive) { if let group = selectedGroup { phone.deleteFavoriteGroup(group.id) } }
                Button("Abbrechen", role: .cancel) {}
            } message: { Text("Ihre Favoriten werden nach Allgemein verschoben.") }
        }
    }
}

struct ContactLabel: View {
    let contact: Contact
    var body: some View {
        HStack(spacing: 12) {
            Avatar(contact: contact)
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name).font(FonadoStyle.font(.headline)).foregroundStyle(.primary)
                Text("\(contact.role) · \(contact.number)").font(FonadoStyle.font(.caption)).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 4)
    }
}

struct RecentsView: View {
    @EnvironmentObject private var phone: PhoneStore
    @State private var missedOnly = false
    @State private var clearConfirmation = false
    private func title(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Heute" }
        if Calendar.current.isDateInYesterday(day) { return "Gestern" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
    var body: some View {
        let days = RecentCallDay.sections(phone.recents, missedOnly: missedOnly)
        List {
            Picker("Anrufe", selection: $missedOnly) {
                Text("Alle").tag(false)
                Text("Verpasst").tag(true)
            }.pickerStyle(.segmented).listRowBackground(Color.clear)
            if days.isEmpty {
                ContentUnavailableView(missedOnly ? "Keine verpassten Anrufe" : "Noch keine Anrufe", systemImage: "phone")
                    .listRowBackground(Color.clear)
            }
            ForEach(days) { day in
              Section(title(day.id)) {
                ForEach(day.groups) { group in
                  let recent = group.latest
                NavigationLink {
                    RecentCallGroupDetails(group: group)
                } label: {
                    HStack(spacing: 12) {
                        Avatar(contact: recent.contact)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recent.contact.name).font(FonadoStyle.font(.headline)).foregroundStyle(recent.missed ? Color.red : Color.primary)
                            Text(group.calls.count > 1 ? "\(group.calls.count) verpasste Anrufe" : recent.detail).font(FonadoStyle.font(.caption)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            if !Calendar.current.isDateInToday(recent.date) {
                                Text(recent.date, format: .dateTime.day().month().year())
                            }
                            Text(recent.date, style: .time)
                        }.font(FonadoStyle.font(.caption)).foregroundStyle(.secondary)
                    }.padding(.vertical, 5)
                }
                .accessibilityLabel("\(recent.contact.name), \(recent.detail), Details")
            }.onDelete { offsets in
                phone.manager.deleteRecents(ids: Set(offsets.flatMap { day.groups[$0].calls.map(\.id) }))
            }
              }
            }
        }
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            if !phone.manager.historyStatus.isEmpty { Text(phone.manager.historyStatus).font(FonadoStyle.font(.caption)).foregroundStyle(.secondary).padding(8) }
        }
        .onAppear { phone.manager.onHistoryRefresh?() }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Anrufliste löschen", role: .destructive) { clearConfirmation = true }
                    .disabled(phone.recents.isEmpty)
            }
        }
        .confirmationDialog(phone.manager.historyStatus.isEmpty ? "Anrufliste auf diesem Gerät löschen?" : "Anrufliste dieses Kontos auf allen Geräten löschen?", isPresented: $clearConfirmation, titleVisibility: .visible) {
            Button("Alle Anrufe löschen", role: .destructive) {
                phone.manager.deleteRecents(ids: Set(phone.recents.map(\.id)))
            }
        }
    }
}

struct RecentCallDetails: View {
    @EnvironmentObject private var phone: PhoneStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var directory = ContactsDirectory()
    @State private var selectNumber = false
    @State private var createContact = false
    let recent: RecentCall
    private var matchingContacts: [DeviceContact] {
        directory.contacts.filter { $0.containsPhoneNumber(recent.contact.number) }
    }
    private var durationText: String {
        guard let duration = recent.duration else { return "Nicht erfasst" }
        let seconds = Int(duration)
        return "\(seconds / 60) Min. \(seconds % 60) Sek."
    }
    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Avatar(contact: recent.contact)
                    VStack(alignment: .leading) {
                        Text(recent.contact.name).font(FonadoStyle.font(.title2, weight: .bold))
                        Text(recent.contact.number).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                }.padding(.vertical, 8)
                LabeledContent("Zeitpunkt", value: recent.date.formatted(date: .abbreviated, time: .standard))
                LabeledContent("Ergebnis", value: recent.detail)
                if let incoming = recent.incoming {
                    LabeledContent("Richtung", value: incoming ? "Eingehend" : "Ausgehend")
                }
                LabeledContent("Gesprächsdauer", value: durationText)
            }
            Section {
                Button {
                    if matchingContacts.contains(where: { $0.numbers.count > 1 }) || matchingContacts.count > 1 {
                        selectNumber = true
                    } else { phone.start(recent.contact) }
                } label: { Label("Zurückrufen", systemImage: "phone.fill") }
                .disabled(directory.isLoading || phone.busy)
                Button { phone.toggleFavorite(recent.contact) } label: {
                    Label(phone.favorites.contains(where: { $0.id == recent.contact.id }) ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen", systemImage: "star")
                }
                if matchingContacts.isEmpty {
                    Button { createContact = true } label: { Label("Als iPhone-Kontakt speichern", systemImage: "person.crop.circle.badge.plus") }
                }
            }
            if !directory.canRead {
                Section {
                    Text("Mit Kontaktzugriff kann Fonado weitere Rufnummern zu diesem Kontakt anbieten.")
                        .font(FonadoStyle.font(.footnote)).foregroundStyle(.secondary)
                    if directory.access == .notRequested {
                        Button("Kontaktzugriff erlauben") { Task { await directory.requestAccess() } }
                    } else {
                        Button("iPhone-Einstellungen öffnen") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                    }
                }
            }
            if let error = directory.errorMessage { Text(error).foregroundStyle(.secondary) }
        }
        .navigationTitle("Anrufdetails")
        .navigationBarTitleDisplayMode(.inline)
        .task { await directory.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await directory.refresh() } }
        }
        .confirmationDialog("Rufnummer wählen", isPresented: $selectNumber, titleVisibility: .visible) {
            Button("Angerufene Nummer: \(recent.contact.number)") { phone.start(recent.contact) }
            ForEach(matchingContacts) { contact in
                ForEach(contact.numbers) { number in
                    Button("\(contact.name) · \(number.label): \(number.value)") { phone.start(contact.callContact(for: number)) }
                }
            }
        }
        .sheet(isPresented: $createContact, onDismiss: { Task { await directory.refresh() } }) {
            NewPhoneContact(contact: recent.contact)
        }
    }
}

struct NewPhoneContact: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let contact: Contact
    func makeCoordinator() -> Coordinator { Coordinator { dismiss() } }
    func makeUIViewController(context: Context) -> UINavigationController {
        let draft = CNMutableContact()
        if contact.name != contact.number { draft.givenName = contact.name }
        draft.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: contact.number))]
        let editor = CNContactViewController(forNewContact: draft)
        editor.delegate = context.coordinator
        editor.contactStore = CNContactStore()
        return UINavigationController(rootViewController: editor)
    }
    func updateUIViewController(_ controller: UINavigationController, context: Context) {}
    final class Coordinator: NSObject, CNContactViewControllerDelegate {
        let completion: () -> Void
        init(completion: @escaping () -> Void) { self.completion = completion }
        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) { completion() }
    }
}

struct NumberKeys: View {
    let press: (String) -> Void
    private let keys = [("1", ""), ("2", "ABC"), ("3", "DEF"), ("4", "GHI"), ("5", "JKL"), ("6", "MNO"), ("7", "PQRS"), ("8", "TUV"), ("9", "WXYZ"), ("*", ""), ("0", "+"), ("#", "")]
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 12) {
            ForEach(keys, id: \.0) { key in
                Button { press(key.0) } label: {
                    VStack(spacing: 0) {
                        Text(key.0).font(FonadoStyle.font(size: 30, relativeTo: .title))
                            .foregroundStyle(FonadoStyle.accent)
                        Text(key.1.isEmpty ? " " : key.1).font(FonadoStyle.font(size: 10, relativeTo: .caption2)).tracking(2)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary).frame(maxWidth: .infinity, minHeight: 67)
                    .background(FonadoStyle.surface, in: RoundedRectangle(cornerRadius: 25))
                    .overlay { RoundedRectangle(cornerRadius: 25).strokeBorder(FonadoStyle.accent.opacity(0.06)) }
                }.accessibilityLabel(key.0)
            }
        }
    }
}

struct DialpadView: View {
    @EnvironmentObject private var phone: PhoneStore
    @State private var number = ""
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(number.isEmpty ? "Nummer eingeben" : number)
                    .font(FonadoStyle.font(.title)).multilineTextAlignment(.center)
                    .foregroundStyle(number.isEmpty ? Color.secondary : Color.primary)
                    .lineLimit(2).minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Telefonnummer")
                    .accessibilityValue(number.isEmpty ? "Noch keine Nummer" : number)
                    .accessibilityHint("Mit dem Wählpad eingeben. Lange drücken, um eine Nummer einzufügen.")
                    .contextMenu {
                        Button {
                            if let pasted = UIPasteboard.general.string {
                                number = String(pasted.filter { "0123456789+*#".contains($0) }.prefix(64))
                            }
                        } label: { Label("Nummer einfügen", systemImage: "doc.on.clipboard") }
                        if !number.isEmpty {
                            Button { UIPasteboard.general.string = number } label: { Label("Nummer kopieren", systemImage: "doc.on.doc") }
                            Button(role: .destructive) { number = "" } label: { Label("Nummer löschen", systemImage: "delete.left") }
                        }
                    }
                    .padding(.top, 10)
                Text("Intern oder extern anrufen")
                    .font(FonadoStyle.font(.subheadline)).foregroundStyle(.secondary)
                NumberKeys { if number.count < 64 { number += $0 } }
                HStack(spacing: 20) {
                    Button("+") { if number.isEmpty { number = "+" } }
                        .frame(maxWidth: .infinity, minHeight: 56).font(FonadoStyle.font(.title2))
                        .accessibilityLabel("Internationale Vorwahl")
                    Button { phone.dial(number) } label: {
                        Image(systemName: "phone.fill").font(FonadoStyle.font(.title2))
                            .frame(maxWidth: .infinity, minHeight: 60)
                    }
                    .buttonStyle(FonadoCallButtonStyle())
                    .disabled(number.isEmpty || phone.busy).accessibilityLabel("Nummer anrufen")
                    Button { if !number.isEmpty { number.removeLast() } } label: {
                        Image(systemName: "delete.left").font(FonadoStyle.font(.title2)).frame(maxWidth: .infinity, minHeight: 56)
                    }.accessibilityLabel("Letzte Ziffer löschen")
                }
            }.frame(maxWidth: 340).padding(24).frame(maxWidth: .infinity)
        }.scrollDismissesKeyboard(.interactively)
    }
}

enum CallSheet: String, Identifiable { case audio, tones, diagnostics, transfer; var id: String { rawValue } }

struct CallView: View {
    @EnvironmentObject private var phone: PhoneStore
    @State private var sheet: CallSheet?
    var body: some View {
        ScrollView {
            if let call = phone.manager.controlledCall {
                VStack(spacing: 18) {
                    Label(call.incoming ? "Fonado · Eingehender Anruf" : "Fonado · Anruf", systemImage: "phone").font(FonadoStyle.font(.subheadline)).foregroundStyle(.secondary)
                        .padding(.bottom, 20)
                    if let original = phone.call, phone.manager.consultation != nil {
                        Label("Gehalten: \(original.displayedContact.name)", systemImage: "pause.circle")
                            .font(FonadoStyle.font(.subheadline)).foregroundStyle(FonadoStyle.accent)
                    }
                    Avatar(contact: call.displayedContact, large: true)
                    Text(call.displayedContact.name).font(FonadoStyle.font(.largeTitle)).multilineTextAlignment(.center)
                    Text(call.displayedContact.number).foregroundStyle(.secondary)
                    Group {
                        if call.phase == .incoming { Text(phone.manager.acceptingCall ? "Anruf wird angenommen …" : "Eingehender Anruf") }
                        else if call.phase == .connecting { Text("Verbindung wird aufgebaut …") }
                        else if call.phase == .ringing { Text("Es klingelt …") }
                        else if call.phase == .ending { Text("Wird beendet …") }
                        else if call.holdPending { Text("Wird umgeschaltet …") }
                        else if call.isHeld { Text("Anruf wird gehalten") }
                        else if call.isRemoteHeld { Text("Gegenstelle hält das Gespräch") }
                        else if let date = call.connectedAt { Text(date, style: .timer).monospacedDigit() }
                    }.font(FonadoStyle.font(.subheadline)).foregroundStyle(FonadoStyle.accent)
                    if phone.manager.consultation != nil || phone.manager.consultationPending {
                        VStack(spacing: 12) {
                            Button("Gespräche verbinden") { phone.manager.completeConsultation() }
                                .buttonStyle(.borderedProminent)
                                .disabled(phone.manager.consultation?.phase != .active || phone.manager.transferPending)
                            Button("Zurück zum ersten Gespräch") { phone.manager.returnToOriginal() }
                                .disabled(phone.manager.transferPending)
                        }.padding(16).frame(maxWidth: .infinity)
                            .background(FonadoStyle.surface, in: RoundedRectangle(cornerRadius: 20))
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 85), spacing: 12)], spacing: 24) {
                        callButton("Stumm", symbol: call.isMuted ? "mic.slash.fill" : "mic", selected: call.isMuted) { phone.toggleMute() }
                        callButton(phone.audioName, symbol: phone.audioDevices.first { $0.id == phone.selectedAudioID }?.symbol ?? "speaker.wave.2") { sheet = .audio }
                        callButton("Tastatur", symbol: "circle.grid.3x3") { sheet = .tones }
                        callButton(call.isHeld ? "Fortsetzen" : "Halten", symbol: call.isHeld ? "play" : "pause", selected: call.isHeld) { phone.toggleHold() }
                            .disabled(phone.manager.consultation != nil || phone.manager.transferPending || phone.manager.consultationPending)
                        callButton("Vermitteln", symbol: "arrow.triangle.branch") { sheet = .transfer }
                            .disabled(!phone.manager.canTransfer)
                    }.padding(.vertical, 30).disabled(call.phase != .active)
                    if call.phase == .incoming {
                        Button { phone.answer() } label: {
                            HStack {
                                if phone.manager.preparingCall || phone.manager.acceptingCall { ProgressView().tint(.white) }
                                Label(phone.manager.acceptingCall ? "Verbindung wird aufgebaut …" : "Annehmen", systemImage: "phone.fill")
                            }.frame(maxWidth: .infinity, minHeight: 40)
                        }.padding(.vertical, 8).buttonStyle(FonadoCallButtonStyle()).disabled(phone.manager.preparingCall || phone.manager.acceptingCall)
                    }
                    Button(role: .destructive) { phone.end() } label: {
                        Label(call.phase == .incoming ? "Ablehnen" : phone.manager.consultation != nil ? "Beide Gespräche beenden" : "Auflegen", systemImage: "phone.down.fill").frame(maxWidth: .infinity, minHeight: 40)
                    }.buttonStyle(.borderedProminent).tint(.red).clipShape(RoundedRectangle(cornerRadius: 20))
                    if let notice = phone.notice { Text(notice).font(FonadoStyle.font(.caption)).foregroundStyle(.secondary) }
                    Button("Diagnose") { sheet = .diagnostics }.font(FonadoStyle.font(.footnote))
                }.frame(maxWidth: 390).padding(26).frame(maxWidth: .infinity)
            }
        }
        .background(FonadoStyle.background.ignoresSafeArea())
        .interactiveDismissDisabled()
        .onChange(of: phone.manager.controlledCall?.id) { _, _ in sheet = nil }
        .onChange(of: phone.manager.controlledCall?.phase) { _, phase in if phase == .ending { sheet = nil } }
        .sheet(item: $sheet) { item in
            switch item {
            case .transfer: TransferSheet()
            case .audio: AudioSheet()
            case .tones: ToneSheet()
            case .diagnostics: NavigationStack { DiagnosticsView(diagnostics: phone.diagnostics) }
            }
        }
    }

    private func callButton(_ title: String, symbol: String, selected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 9) {
                Image(systemName: symbol).font(FonadoStyle.font(.title2))
                    .frame(width: 66, height: 66)
                    .background(selected ? FonadoStyle.accent : FonadoStyle.surface, in: RoundedRectangle(cornerRadius: 23))
                    .foregroundStyle(selected ? Color(uiColor: .systemBackground) : Color.primary)
                Text(title).font(FonadoStyle.font(.caption)).foregroundStyle(.primary)
            }.frame(maxWidth: .infinity)
        }.accessibilityValue(selected ? "Aktiv" : "")
    }
}

struct AudioSheet: View {
    @EnvironmentObject private var phone: PhoneStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(phone.audioDevices) { route in
                        Button { phone.setAudio(route.id) } label: {
                            HStack {
                                Label(route.name, systemImage: route.symbol)
                                    .foregroundStyle(phone.selectedAudioID == route.id ? FonadoStyle.accent : .primary)
                                Spacer()
                                if phone.selectedAudioID == route.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(FonadoStyle.accent)
                                }
                            }
                        }
                    }
                    if phone.audioDevices.isEmpty { Text("Kein Audioausgang verfügbar") }
                }
                if let notice = phone.notice { Text(notice).foregroundStyle(.secondary) }
                Text("Der Haken zeigt, wo du dein Gespräch hörst.").font(FonadoStyle.font(.footnote)).foregroundStyle(.secondary)
            }
            .navigationTitle("Audioausgabe").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
            .task { phone.manager.refreshAudioDevices() }
        }
        .presentationDetents([.medium, .large])
        .tint(FonadoStyle.accent)
    }
}

struct ToneSheet: View {
    @EnvironmentObject private var phone: PhoneStore
    var body: some View {
        VStack(spacing: 20) {
            Text("Tastatur").font(FonadoStyle.font(.title2))
            Text(toneDisplay)
                .font(FonadoStyle.font(.headline)).lineLimit(2).minimumScaleFactor(0.7)
            NumberKeys { phone.sendTone($0) }
        }.padding(24).background(FonadoStyle.background)
            .presentationDetents([.large]).presentationDragIndicator(.visible)
    }

    private var toneDisplay: String {
        guard let tones = phone.manager.controlledCall?.tones, !tones.isEmpty else { return "Ziffern für das Sprachmenü" }
        return tones
    }
}

struct SettingsView: View {
    @EnvironmentObject private var phone: PhoneStore
    @EnvironmentObject private var customer: CustomerAccount
    @Environment(\.dismiss) private var dismiss
    @AppStorage("fonado.startTab") private var startTab = HomeTab.favorites.rawValue
    @State private var showAvailability = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink { CustomerAccountView() } label: { Label("Fonado-Konto", systemImage: "person.crop.circle") }
                }
                Section("Telefonie") {
                    LabeledContent("Status", value: phone.registration.label)
                    if customer.teamContext != nil {
                        Button { showAvailability = true } label: {
                            Label("Anrufprofile & Rufteams", systemImage: "person.crop.circle.badge.clock")
                        }
                    } else {
                        Toggle("Nicht stören", isOn: $phone.doNotDisturb)
                    }
                    NavigationLink { CallForwardingView() } label: {
                        Label("Anrufumleitung", systemImage: "arrowshape.turn.up.right")
                    }
                }
                Section {
                    Picker("Startansicht", selection: $startTab) {
                        Text("Favoriten").tag(HomeTab.favorites.rawValue)
                        Text("Wählpad").tag(HomeTab.keypad.rawValue)
                        Text("Team").tag(HomeTab.team.rawValue)
                    }
                } footer: { Text("Gilt beim nächsten App-Start. Ohne Favoriten öffnet sich das Wählpad.") }
                Section("Damit Gespräche mehr bewegen.") {
                    FonadoWordmark()
                    Text("Fonado v0.1 · Cloud-Telefonie")
                    Text("Mit aktiviertem Cloud-Push erreichen dich Anrufe auch bei geschlossener App. Die letzten 100 abgeschlossenen Anrufe und deine Favoriten bleiben lokal auf diesem iPhone gespeichert.")
                        .font(FonadoStyle.font(.footnote)).foregroundStyle(.secondary)
                }
            }.scrollContentBackground(.hidden).background(FonadoStyle.background)
                .navigationTitle("Fonado").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }
        .sheet(isPresented: $showAvailability) { AvailabilityView() }
    }
}

struct RecentCallGroupDetails: View {
    let group: RecentCallGroup
    var body: some View {
        if group.calls.count == 1 { RecentCallDetails(recent: group.latest) }
        else {
            List(group.calls) { call in
                NavigationLink { RecentCallDetails(recent: call) } label: {
                    VStack(alignment: .leading) {
                        Text(call.contact.name)
                        Text(call.date, format: .dateTime.hour().minute().second()).foregroundStyle(.secondary)
                    }
                }
            }.navigationTitle("\(group.calls.count) verpasste Anrufe")
        }
    }
}

struct TransferSheet: View {
    @EnvironmentObject private var phone: PhoneStore
    @Environment(\.dismiss) private var dismiss
    @State private var number = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Ziel") {
                    TextField("Durchwahl oder Telefonnummer", text: $number).keyboardType(.phonePad)
                    if !phone.favorites.isEmpty {
                        Menu("Favorit auswählen") {
                            ForEach(phone.favorites) { contact in
                                Button("\(contact.name) · \(contact.number)") { number = contact.number }
                            }
                        }
                    }
                }
                Section {
                    Button("Erst Rücksprache halten") { phone.manager.beginConsultation(number); dismiss() }
                    Button("Direkt vermitteln") { phone.manager.transferDirect(number); dismiss() }
                } footer: {
                    Text("Bei Rücksprache wird dein bisheriges Gespräch gehalten. Danach kannst du verbinden oder zum ursprünglichen Gespräch zurückkehren.")
                }.disabled(number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !phone.manager.canTransfer)
            }
            .navigationTitle("Vermitteln").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } } }
        }.tint(FonadoStyle.accent)
    }
}


struct CallForwardingView: View {
    @EnvironmentObject private var customer: CustomerAccount
    @Environment(\.scenePhase) private var scenePhase
    @State private var mode = "off"
    @State private var target = ""
    @State private var saved: CallForwardingSettings?
    @State private var busy = false
    @State private var message = ""
    @FocusState private var editingTarget: Bool
    private var tenantID: String? { customer.activeCloudMembership?.id }
    private var changed: Bool { saved.map { mode != $0.mode || (mode != "off" && target != $0.target) } ?? false }
    var body: some View {
        Form {
            if let membership = customer.activeCloudMembership {
                Section {
                    LabeledContent("Firma", value: membership.name)
                    LabeledContent("Deine Nebenstelle", value: membership.number ?? "–")
                }
                if saved != nil {
                    Section {
                        Picker("Umleitung", selection: $mode) {
                            Text("Aus").tag("off")
                            Text("Immer").tag("always")
                            Text("Bei besetzt").tag("busy")
                        }
                        if mode != "off" {
                            TextField("Nebenstelle oder +43 …", text: $target)
                                .keyboardType(.phonePad).textContentType(.telephoneNumber)
                                .focused($editingTarget).accessibilityLabel("Ziel der Umleitung")
                        }
                    } footer: {
                        Text(mode == "busy" ? "Leitet weiter, wenn deine Fonado-Nebenstelle bereits telefoniert oder Besetzt zurückmeldet. Nicht-Abheben löst keine Umleitung aus." : "Die Umleitung gilt auf der Telefonanlage, auch wenn die App geschlossen ist.")
                    }
                    if mode != "off" {
                        Section {
                            Label("Interne Nebenstelle oder österreichische Rufnummer", systemImage: "phone.arrow.up.right")
                                .font(FonadoStyle.font(.footnote))
                        } footer: {
                            Text(saved?.external_available == true ? "Externe Umleitungen laufen über euren Telefonanschluss. Dabei können Gesprächskosten entstehen." : "Externe Umleitungen benötigen einen aktiven Telefonanschluss. Interne Ziele müssen bereits eingerichtet sein.")
                        }
                    }
                    Section {
                        Button { Task { await save() } } label: {
                            Label("Umleitung speichern", systemImage: "checkmark.circle.fill")
                        }.disabled(!changed || (mode != "off" && target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                        Label(statusText, systemImage: saved?.status == "applied" ? "checkmark.circle" : "clock")
                            .font(FonadoStyle.font(.footnote)).foregroundStyle(.secondary)
                        Button("Status aktualisieren") { Task { await load(reset: false) } }
                    }
                }
            } else {
                Section {
                    Text("Bitte zuerst mit deinem Fonado-Konto anmelden und deine Firma verbinden.")
                    NavigationLink("Zum Fonado-Konto") { CustomerAccountView() }
                }
            }
            if busy { ProgressView("Bitte warten …") }
            if !message.isEmpty { Section { Text(message).font(FonadoStyle.font(.callout)) } }
            if saved == nil && tenantID != nil && !busy {
                Button("Erneut laden") { Task { await load(reset: true) } }
            }
        }
        .disabled(busy)
        .scrollContentBackground(.hidden).background(FonadoStyle.background)
        .navigationTitle("Anrufumleitung").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Fertig") { editingTarget = false } } }
        .task(id: tenantID) { saved = nil; mode = "off"; target = ""; await load(reset: true) }
        .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await load(reset: false) } } }
    }
    private var statusText: String {
        if changed { return "Änderung noch nicht gespeichert" }
        switch saved?.status {
        case "applied": return saved?.mode == "off" ? "Keine Umleitung aktiv" : "Umleitung auf der Telefonanlage aktiv"
        case "unavailable": return "Gespeichert · Telefonie oder Anschluss derzeit nicht verfügbar"
        default: return "Gespeichert · Übernahme durch die Telefonanlage ausstehend"
        }
    }
    private func load(reset: Bool) async {
        guard !busy, let id = tenantID else { return }
        busy = true; message = ""
        defer { busy = false }
        do {
            let result = try await customer.forwardingSettings(tenantID: id)
            let keepEdit = !reset && changed
            if !keepEdit { saved = result; mode = result.mode; target = result.target }
        } catch is CancellationError { return }
        catch { message = error.localizedDescription }
    }
    private func save() async {
        guard !busy, let saved, let id = tenantID else { return }
        editingTarget = false; busy = true; message = ""
        defer { busy = false }
        do {
            let result = try await customer.saveForwarding(tenantID: id, mode: mode, target: target, revision: saved.revision)
            self.saved = result; mode = result.mode; target = result.target
            message = "Umleitung gespeichert."
            // One bounded refresh; no background polling or SIP re-registration.
            try await Task.sleep(for: .seconds(6))
            self.saved = try await customer.forwardingSettings(tenantID: id)
        } catch is CancellationError { return }
        catch { message = error.localizedDescription }
    }
}
