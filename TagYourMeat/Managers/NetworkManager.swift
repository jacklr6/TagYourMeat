//
//  NetworkManager.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/23/25.
//

import Foundation
import Network

class NetworkManager: ObservableObject {
    private var monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected: Bool = true

    init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
