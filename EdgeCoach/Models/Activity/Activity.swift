// MARK: - Activity Model (API Response)

import Foundation

/// Modèle correspondant exactement à la réponse de l'API /activities/history
/// FORMAT PIVOT: Utilise activity_id, provider, external_id pour l'identification
struct Activity: Codable, Identifiable, Hashable {
    // Hashable conformance based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.id == rhs.id
    }

    // === IDENTIFIANTS FORMAT PIVOT ===
    let _id: String?            // _id MongoDB (optionnel)
    var id: String { _id ?? activityId ?? UUID().uuidString }
    let activityId: String?     // activity_id (UUID) - NOUVEAU FORMAT PIVOT
    let provider: String?       // Provider source: "nolio", "wahoo", "fit_file", "tcx_file", etc.
    let externalId: String?     // ID externe du système source (ex-nolio_id, wahoo_id)
    let userId: String

    // === INFOS DE BASE ===
    let dateStart: String       // date_start (YYYY-MM-DD ou ISO)
    let startTime: String?      // Heure de début ISO
    let sport: String?          // Sport normalisé (cycling, running, swimming)
    let name: String?
    let description: String?
    let isCompetition: Bool?

    // === MÉTRIQUES (toutes depuis file_datas) ===
    // Note: Les métriques sont maintenant accessibles uniquement via fileDatas
    // Utiliser les computed properties: preferredDuration, preferredDistance, etc.

    // === FEEDBACK SUBJECTIF ===
    let rpe: Int?               // Rating of Perceived Exertion (0-10)
    let feeling: Int?           // Ressenti (0-5)

    // === PLANIFICATION ===
    let plannedSessionId: String? // ID séance planifiée liée
    let plannedName: String?
    let plannedDescription: String?

    // === SOURCE FICHIER ===
    let fileUrl: String?
    let fileHash: String?       // Hash SHA256 pour déduplication

    // === DONNÉES COMPLÈTES ===
    let fileDatas: ActivityFileData?

    // === MÉTADONNÉES ===
    let cachedAt: String?
    let createdAt: String?
    let updatedAt: String?

    // === COMPUTED PROPERTIES (compatibilité) ===

    /// Discipline calculée depuis le sport
    var discipline: Discipline {
        Discipline.from(sport: sport)
    }

    enum CodingKeys: String, CodingKey {
        // === IDENTIFIANTS FORMAT PIVOT ===
        case _id
        case activityId = "activity_id"
        case provider
        case externalId = "external_id"
        case userId = "user_id"

        // === INFOS DE BASE ===
        case dateStart = "date_start"
        case startTime = "start_time"
        case sport
        case name
        case description
        case isCompetition = "is_competition"

        // === MÉTRIQUES (toutes depuis file_datas) ===
        // Les métriques sont maintenant uniquement dans file_datas

        // === FEEDBACK SUBJECTIF ===
        case rpe
        case feeling

        // === PLANIFICATION ===
        case plannedSessionId = "planned_session_id"
        case plannedName = "planned_name"
        case plannedDescription = "planned_description"

        // === SOURCE FICHIER ===
        case fileUrl = "file_url"
        case fileHash = "file_hash"

        // === DONNÉES COMPLÈTES ===
        case fileDatas = "file_datas"

        // === MÉTADONNÉES ===
        case cachedAt = "cached_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // === IDENTIFIANTS FORMAT PIVOT ===
        _id = try container.decodeIfPresent(String.self, forKey: ._id)
        activityId = try container.decodeIfPresent(String.self, forKey: .activityId)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        userId = try container.decode(String.self, forKey: .userId)

        // === INFOS DE BASE ===
        dateStart = try container.decode(String.self, forKey: .dateStart)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        sport = try container.decodeIfPresent(String.self, forKey: .sport)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isCompetition = try container.decodeIfPresent(Bool.self, forKey: .isCompetition)

        // === MÉTRIQUES ===
        // Toutes les métriques sont maintenant dans file_datas

        // === FEEDBACK SUBJECTIF ===
        rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
        feeling = try container.decodeIfPresent(Int.self, forKey: .feeling)

        // === PLANIFICATION ===
        plannedSessionId = try container.decodeIfPresent(String.self, forKey: .plannedSessionId)
        plannedName = try container.decodeIfPresent(String.self, forKey: .plannedName)
        plannedDescription = try container.decodeIfPresent(String.self, forKey: .plannedDescription)

        // === SOURCE FICHIER ===
        fileUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl)
        fileHash = try container.decodeIfPresent(String.self, forKey: .fileHash)

        // === DONNÉES COMPLÈTES ===
        // file_datas peut être un String (JSON) ou un Object
        if let data = try? container.decodeIfPresent(ActivityFileData.self, forKey: .fileDatas) {
            fileDatas = data
        } else if let jsonString = try? container.decodeIfPresent(String.self, forKey: .fileDatas) {
            if let data = jsonString.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(ActivityFileData.self, from: data) {
                fileDatas = decoded
            } else {
                fileDatas = nil
            }
        } else {
            fileDatas = nil
        }

        // === MÉTADONNÉES ===
        cachedAt = try container.decodeIfPresent(String.self, forKey: .cachedAt)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // === IDENTIFIANTS FORMAT PIVOT ===
        try container.encodeIfPresent(_id, forKey: ._id)
        try container.encodeIfPresent(activityId, forKey: .activityId)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encode(userId, forKey: .userId)

        // === INFOS DE BASE ===
        try container.encode(dateStart, forKey: .dateStart)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(sport, forKey: .sport)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(isCompetition, forKey: .isCompetition)

        // === MÉTRIQUES ===
        // Toutes les métriques sont dans file_datas

        // === FEEDBACK SUBJECTIF ===
        try container.encodeIfPresent(rpe, forKey: .rpe)
        try container.encodeIfPresent(feeling, forKey: .feeling)

        // === PLANIFICATION ===
        try container.encodeIfPresent(plannedSessionId, forKey: .plannedSessionId)
        try container.encodeIfPresent(plannedName, forKey: .plannedName)
        try container.encodeIfPresent(plannedDescription, forKey: .plannedDescription)

        // === SOURCE FICHIER ===
        try container.encodeIfPresent(fileUrl, forKey: .fileUrl)
        try container.encodeIfPresent(fileHash, forKey: .fileHash)

        // === DONNÉES COMPLÈTES ===
        try container.encodeIfPresent(fileDatas, forKey: .fileDatas)

        // === MÉTADONNÉES ===
        try container.encodeIfPresent(cachedAt, forKey: .cachedAt)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    // MARK: - Init for Preview/Testing

    init(
        id: String,
        userId: String,
        dateStart: String,
        sport: String? = nil,
        name: String? = nil,
        description: String? = nil,
        fileDatas: ActivityFileData? = nil
    ) {
        self._id = id
        self.activityId = nil
        self.provider = nil
        self.externalId = nil
        self.userId = userId
        self.dateStart = dateStart
        self.startTime = nil
        self.sport = sport
        self.name = name
        self.description = description
        self.isCompetition = nil
        self.rpe = nil
        self.feeling = nil
        self.plannedSessionId = nil
        self.plannedName = nil
        self.plannedDescription = nil
        self.fileUrl = nil
        self.fileHash = nil
        self.fileDatas = fileDatas
        self.cachedAt = nil
        self.createdAt = nil
        self.updatedAt = nil
    }
}
