//
//  URLSessionEngineRTM.swift
//  
//
//  Created by Daniel Larsen on 7/7/22.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif

public class URLSessionEngineRTM: NSObject, RTMWebSocket {

    public var delegate: RTMDelegate?

    private var session: URLSession?
    private var webSocketTask: URLSessionWebSocketTask?

    public required override init() {}

    public func connect(url: URL) {
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()

        listen()
    }

    public func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    public func sendMessage(_ message: String) throws {
        Task {
            try await webSocketTask?.send(.string(message))
        }
    }

    private func listen() {
        Task {
            do {
                let message = try await webSocketTask?.receive()

                if case .string(let text) = message {
                    delegate?.receivedMessage(text)
                }
            } catch {
                debugPrint("Error receiving message. \(error)")
            }

            listen()
        }
    }
}

extension URLSessionEngineRTM: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        delegate?.didConnect()
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        delegate?.disconnected()
    }
}
