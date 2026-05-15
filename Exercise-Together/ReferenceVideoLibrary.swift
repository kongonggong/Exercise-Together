import Foundation

enum ReferenceVideoLibrary {
    private static let aliases = [
        "2-Curl_Forearm": "forearm-curl",
        "2-Curl_Upper-Arms": "biceps-curl",
        "2-Curl-Upper-Arms": "biceps-curl-alt",
        "3-Shoulders": "shoulder-press",
        "4-Lateral-Raise-": "lateral-raise",
        "5-Front-Raise": "front-raise",
        "6-Arm-Triceps-Extension": "triceps-extension",
        "6-Overhead-Triceps-Extension": "overhead-triceps-extension",
        "7-Incline-Row_Back": "incline-row",
        "7-Inverted-Row_Back": "inverted-row",
        "Pull-up_Back": "pull-up"
    ]

    static func url(for rawName: String?) -> URL? {
        guard let rawName,
              !rawName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let nameWithoutExtension = (rawName as NSString).deletingPathExtension
        let resolvedName = aliases[nameWithoutExtension] ?? nameWithoutExtension

        for subdirectory in [nil, "Videos", "Resources/Videos"] as [String?] {
            if let url = Bundle.main.url(
                forResource: resolvedName,
                withExtension: "mp4",
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        return nil
    }
}
