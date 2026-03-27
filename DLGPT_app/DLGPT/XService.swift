import Foundation

struct XService {
    func fetchSummary(maxItems: Int, timeWindowHours: Int?) async throws -> XSummary {
        guard let url = URL(string: "http://127.0.0.1:8000/x-summary") else {
            throw XError.badBackendResponse(
                message: "The backend URL is invalid.",
                retryable: false,
                requestId: nil
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = XSummaryRequest(
            userId: "david",
            maxItems: maxItems,
            summaryType: "digest",
            timeWindowHours: timeWindowHours
        )

        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw XError.badBackendResponse(
                    message: "The backend returned an invalid response.",
                    retryable: false,
                    requestId: nil
                )
            }

            if 200..<300 ~= httpResponse.statusCode {
                do {
                    return try JSONDecoder().decode(XSummary.self, from: data)
                } catch {
                    throw XError.decodingFailure
                }
            } else {
                do {
                    let backendError = try JSONDecoder().decode(XBackendErrorResponse.self, from: data)
                    throw XError.fromBackend(backendError)
                } catch let xError as XError {
                    throw xError
                } catch {
                    throw XError.badBackendResponse(
                        message: "The backend returned an unreadable error response.",
                        retryable: false,
                        requestId: nil
                    )
                }
            }
        } catch let xError as XError {
            throw xError
        } catch {
            throw XError.networkFailure
        }
    }
}

private struct XSummaryRequest: Encodable {
    let userId: String
    let maxItems: Int
    let summaryType: String
    let timeWindowHours: Int?
}
