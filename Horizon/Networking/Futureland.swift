// By Tom Meagher on 1/23/21 at 14:22

import Alamofire
import Foundation
import Combine

enum Futureland {
    // TODO: Standardize token passing and headers
    // https://swiftwithmajid.com/2020/01/08/building-networking-layer-using-functions/
    private static var baseURL: URL {
        guard let url = URL(string: "https://api.futureland.tv") else {
            fatalError("FAILED: https://api.futureland.tv")
        }
        return url
    }

    /// Gets journals for signed in user
    static func createEntry(
        token: String,
        notes: String,
        journalId: Int,
        file: File?,
        isPrivate: Bool
    ) -> UploadRequest {
        let url = baseURL.appendingPathComponent("/entries")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("token=\(token)", forHTTPHeaderField: "Cookie")
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let streakDate = formatter.string(from: now)
        
        let fileData = file?.data ?? Data()
        let fileName = file?.name
        let mimeType = file?.mimeType
        
        return AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(Data(notes.utf8), withName: "notes")
            multipartFormData.append(Data(streakDate.utf8), withName: "streakDate")
            multipartFormData.append(Data("\(journalId)".utf8), withName: "journal_id")
            multipartFormData.append(Data("\(isPrivate)".utf8), withName: "private")
            multipartFormData.append(fileData, withName: "file", fileName: fileName, mimeType: mimeType)
        }, with: request)
    }

    /// Gets journals for signed in user
    static func journals(token: String) -> AnyPublisher<[Journal], AFError> {
        let url = baseURL.appendingPathComponent("/users/log")
        let headers = HTTPHeaders([
            HTTPHeader(name: "Content-Type", value: "application/json"),
            HTTPHeader(name: "Cookie", value: "token=\(token)")
        ])
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        
        return AF
            .request(url, method: .get, headers: headers)
            .publishDecodable(type: [Journal].self, decoder: decoder)
            .value()
    }

    /// Sign in and get token
    static func login(email: String, password: String) -> AnyPublisher<AuthUser, AFError> {
        let url = baseURL.appendingPathComponent("/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: Any] = ["email": email, "password": password]
        let body = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = body
        
        return AF
            .request(request)
            .publishDecodable(type: AuthUser.self)
            .value()
    }
}
