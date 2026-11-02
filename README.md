# Fonado für iOS

Native SwiftUI-App ab iOS 17 mit Liblinphone 5.5.23. Bundle-ID `ai.fonado.ios`; Xcode-Scheme **FonadoAI**. Dieses Repository enthält ausschließlich App-Quellen, App-Konfiguration, Assets, Lizenzen und isolierte Prüfungen. Der Telefonie-/Kontoserver wird separat im [Server-Repository](https://github.com/ivama-dev/fonado) verwaltet.

## Bauen und prüfen

Xcode 27 und Swift auf macOS verwenden. Das bestehende Entwicklungsteam ist im Projekt hinterlegt; eine andere Installation muss ihre eigene passende Signierung einrichten. Private Schlüssel, Provisionierungsprofile und lokale Kontodaten werden nicht übertragen.

```sh
bash ios/Checks/run-checks.sh
python3 ios/Checks/customer-provisioning-checks.py
xcodebuild -project ios/FonadoAI.xcodeproj -scheme FonadoAI \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/FonadoAI-ios-build \
  -clonedSourcePackagesDirPath build/SourcePackages build
```

Simulator-Builds regulär signieren: Ohne App-Identität kann der Schlüsselbund die Anmeldung verweigern. Der Simulator verwendet die eigene Anrufoberfläche; Push, native Anrufsteuerung, CarPlay und WLAN/LTE-Übergänge müssen auf einem echten iPhone geprüft werden.

## Funktionen und Struktur

Favoriten unterstützen eigene Gruppen mit frei gewählter Reihenfolge. Unter **Favoriten → Bearbeiten** lassen sich Gruppen anlegen, umbenennen und am Griff nach oben oder unten verschieben. Im Bereich **Favoriten** desselben Editors werden Kontakte einer Gruppe zugeordnet und innerhalb ihrer Gruppe sortiert. Beim Löschen einer Gruppe werden ihre Favoriten nach **Allgemein** verschoben. Bestehende Favoriten werden einmalig für das bestätigte bisherige Konto übernommen; die alte Datei bleibt erhalten.

Favoriten und Gruppen werden nach der Anmeldung automatisch mit dem persönlichen Fonado-Konto synchronisiert. Gruppen anlegen, umbenennen, löschen und sortieren sowie Kontakte zuordnen oder sortieren gilt auf jedem Gerät. Die Gruppe **Allgemein** bleibt erhalten; beim Löschen einer eigenen Gruppe werden deren Favoriten dorthin verschoben. Nur ausgewählte Favoriten werden übertragen, nicht das gesamte Adressbuch. Es gibt keinen Schalter zum Starten oder Beenden der Synchronisierung.

Änderungen funktionieren offline und werden bei der nächsten Verbindung abgeglichen. Gleichzeitige Änderungen werden anhand des letzten bestätigten Kontostands zusammengeführt; bei konkurrierenden Änderungen desselben Feldes gewinnt die noch ausstehende lokale Änderung beim erneuten Speichern. Löschungen haben Vorrang vor veralteten Kopien. Der automatische Worker wiederholt Revisionskonflikte höchstens dreimal pro Durchlauf und prüft im Vordergrund alle fünf Sekunden. Abmelden leert die Anzeige und schützt vor verspäteten Antworten einer alten Sitzung. Andere Benutzer und Firmenadministratoren haben keinen Zugriff auf die persönlichen Favoriten.

Bestehende Favoriten werden einmalig dem bestätigten bisherigen Konto zugeordnet. Die alte Datei bleibt unverändert. Alte Favoriten ohne belegte Kontozuordnung erfordern weiterhin **Vorhandene Favoriten übernehmen**, damit die Favoriten einer anderen Person nicht versehentlich übertragen werden.

Die übernommene Telefoniebasis enthält die automatische Synchronisierung. Gemeinsame Swift-/Windows-Testdaten prüfen Gruppen, Felder, Zuordnung, Reihenfolge und Löschungen. Die Worker-Prüfungen decken Offline-Neustart, zwei Geräte, begrenzte Revisionswiederholungen, Änderungen während eines Uploads, verlorene Antworten, Kontowechsel und beschädigte Caches ab. API: `GET/POST /v1/cloud/favorites`, Schema 1, Revision pro Benutzer, verschlüsselte serverseitige Speicherung.

Echte Geräteabnahme zwischen iPhone, Mac und Windows bleibt erforderlich. Ein erfolgreicher Quellbuild bestätigt keine Veröffentlichung in TestFlight oder im Windows Store.

`ios/FonadoAI/` enthält Anmeldung und automatische Cloud-Nebenstelle, Geräteprofile, Team/Präsenz, Kontakte/Favoriten, synchronisierte Anrufhistorie, Weiterleitungen und Gesprächssteuerung. VoIP-Push, CallKit/LiveCommunicationKit, Siri und CarPlay bleiben erhalten. `SIPConnectionCoordinator` serialisiert Wiederverbindungen; `LinphoneSIPCore` kapselt die einzige Telefonie-Engine. Zertifikatsprüfung, Pflicht-SRTP und gerätegebundene Schlüsselbundablage bleiben aktiv.

Die [Mac-App](https://github.com/ivama-dev/fonado-macos) übernimmt einen kontrollierten Stand der gemeinsamen Dateien. Änderungen an Konto-, Verbindungs- und API-Modellen müssen auf beiden Plattformen abgestimmt werden.

## Eigenständige App

Fonado wird als eigene iOS-App mit Bundle-ID `ai.fonado.ios`, SKU `fonado-ai-ios` und eigener TestFlight-Verteilung aufgebaut. Der erste Build dieser App hat Version **0.1.0 (1)**. Die bisherige App kann parallel installiert bleiben; Fonado ist kein Update ihrer App-Store-Identität.

Lokale Einstellungen, Favoriten-/Verlaufscaches und Schlüsselbunddaten besitzen einen eigenen Namensraum (`fonado.*` bzw. `FonadoAI`). Das gemeinsame Firmenkonto kann nach erneuter Anmeldung dieselben persönlichen Cloud-Daten laden. Es findet kein Zugriff auf den lokalen Datencontainer der bisherigen App statt.

## Lizenz

Die Fonado-iOS-App steht wie der Windows-Client unter **GNU Affero General Public License v3 oder später** (`AGPL-3.0-or-later`). Siehe [LICENSE](LICENSE) und [NOTICE.md](NOTICE.md). Drittanbieter behalten ihre eigenen Lizenzen; [Hinweise und unveränderte Lizenzdateien](THIRD-PARTY-NOTICES.md). Automatische GitHub-Prüfungen verwenden synthetische Daten und benötigen keine Produktionszugänge.

## Markenname und technische Kompatibilität

Das Xcode-Projekt, Target, Scheme und der Quellordner heißen **FonadoAI**; sichtbarer App-Name ist **Fonado**. Die neue Bundle-ID und lokalen Speicherkennungen trennen diese App von ihrer Vorgängerin. Die bestehenden Backend-Adressen und gemeinsam verwendeten Push-/API-Protokolle bleiben für die gemeinsame Telefonieplattform kompatibel; sie sind keine sichtbaren Produktnamen.

## Markenstand Fonado

Die App und die Wortmarke heißen **Fonado**. Die Wortmarke verwendet die gelieferten Symbol- und Buchstabenkonturen ohne den bisherigen Namenszusatz. Das App-Icon bleibt unverändert. Die lokal mitgelieferten Manrope-Schriften skalieren mit Dynamic Type. Hell-/Dunkelmodus verwenden eine adaptive Palette; grüne Aktionsflächen haben anthrazitfarbenen Text. Die Schriftlizenz liegt unter `ios/FonadoAI/Fonts/OFL.txt`.

Build **0.1.0 (2)** enthält die Wortmarke **Fonado** ohne Namenszusatz. Die Domain `fonado.ai`, Bundle-ID und technischen Modulnamen bleiben erhalten.
