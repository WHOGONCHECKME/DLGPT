//
//  XError.swift
//  DLGPT
//
//  Created by David on 14/3/2026.
//

import Foundation

struct XBackendErrorResponse: Decodable {
    let errorCode: String
    let message: String
    let retryable: Bool
    let requestId: String?
}

enum XError: Error {
    case invalidUserId(message: String, retryable: Bool, requestId: String?)
    case invalidMaxItems(message: String, retryable: Bool, requestId: String?)
    case unsupportedSummaryType(message: String, retryable: Bool, requestId: String?)
    case invalidTimeWindowHours(message: String, retryable: Bool, requestId: String?)
    case xFetchFailed(message: String, retryable: Bool, requestId: String?)
    case noAnalysableContent(message: String, retryable: Bool, requestId: String?)
    case openAIFailed(message: String, retryable: Bool, requestId: String?)
    case timeout(message: String, retryable: Bool, requestId: String?)
    case internalError(message: String, retryable: Bool, requestId: String?)
    case badBackendResponse(message: String, retryable: Bool, requestId: String?)
    case networkFailure
    case decodingFailure
    case unknown(message: String, retryable: Bool, requestId: String?)

    static func fromBackend(_ backendError: XBackendErrorResponse) -> XError {
        switch backendError.errorCode {
        case "invalid_user_id":
            return .invalidUserId(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        case "invalid_max_items":
            return .invalidMaxItems(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        case "unsupported_summary_type":
            return .unsupportedSummaryType(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        case "invalid_time_window_hours":
            return .invalidTimeWindowHours(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        case "x_fetch_failed":
            return .xFetchFailed(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        case "no_analysable_content":
            return .noAnalysableContent(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        case "openai_failed":
            return .openAIFailed(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        case "timeout":
            return .timeout(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        case "internal_error":
            return .internalError(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        case "bad_backend_response":
            return .badBackendResponse(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        default:
            return .unknown(
                message: backendError.message,
                retryable: backendError.retryable,
                requestId: backendError.requestId
            )
        }
    }
}
