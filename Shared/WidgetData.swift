import Foundation

/// Data shared between the main app and widget via direct file in the widget's sandbox container.
///
/// The main app (non-sandboxed) writes a JSON file into the widget extension's container directory.
/// The widget (sandboxed) reads from its own Application Support, which maps to the same path.
struct WidgetAccountData: Codable {
    let email: String          // pre-obfuscated
    let displayName: String    // pre-obfuscated
    let subscriptionType: String?
    let isActive: Bool
    let sessionUtilization: Double?
    let sessionResetTime: String?
    let weeklyUtilization: Double?
    let weeklyResetTime: String?
    let extraUsageEnabled: Bool?
    let hasError: Bool
    let errorMessage: String?
}

struct WidgetData: Codable {
    let accounts: [WidgetAccountData]
    let todayCost: Double
    let conversationTurns: Int
    let activeCodingTime: String
    let linesWritten: Int
    let modelUsage: [String: Int]
    let lastUpdated: Date

    private static let appGroupID = "group.me.neonwatty.runscope"
    private static let legacyAppGroupID = "group.me.local.ccswitcher.codex"
    private static let fileName = "widget-data.json"

    private static var sharedContainerURL: URL? {
        containerURL(for: appGroupID)
    }

    private static func containerURL(for appGroupID: String) -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private static func readData(from appGroupID: String) -> Data? {
        guard let containerURL = containerURL(for: appGroupID) else { return nil }
        let fileURL = containerURL.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    /// Load from the shared App Group container.
    static func load() -> WidgetData? {
        if let data = readData(from: appGroupID) {
            return try? JSONDecoder().decode(WidgetData.self, from: data)
        }

        guard let legacyData = readData(from: legacyAppGroupID),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: legacyData) else {
            return nil
        }

        if let containerURL = sharedContainerURL {
            let fileURL = containerURL.appendingPathComponent(fileName)
            try? legacyData.write(to: fileURL, options: .atomic)
        }

        return decoded
    }

    /// Save to the shared App Group container.
    func save() {
        guard let containerURL = Self.sharedContainerURL else { return }
        let fileURL = containerURL.appendingPathComponent(Self.fileName)
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
