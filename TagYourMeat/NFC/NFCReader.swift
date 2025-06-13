//
//  NFCReader.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/7/25.
//

import CoreNFC

class NFCReader: NSObject {
    private var session: NFCNDEFReaderSession?
    private var onRead: ((String?, Error?) -> Void)?

    func beginReading(onRead: @escaping (String?, Error?) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            onRead(nil, NSError(domain: "NFCReader", code: 0, userInfo: [NSLocalizedDescriptionKey: "NFC is not available on this device"]))
            return
        }
        
        self.onRead = onRead
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone near the NFC tag to read."
        session?.begin()
    }
}

extension NFCReader: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        onRead?(nil, error)
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        var result = ""
        
        for message in messages {
            for record in message.records {
                print("TNF: \(record.typeNameFormat.rawValue), Type: \(String(describing: String(data: record.type, encoding: .utf8)))")
                print("Payload: \(record.payload as NSData)")
                
                guard record.typeNameFormat == .nfcWellKnown,
                      let typeString = String(data: record.type, encoding: .utf8),
                      typeString == "T" else {
                    continue
                }

                let payload = record.payload
                guard payload.count > 1 else {
                    result += "[Empty or invalid payload]\n"
                    continue
                }

                let statusByte = payload[0]
                let isUTF16 = (statusByte & 0x80) != 0
                let langCodeLength = Int(statusByte & 0x3F)

                let textData = payload.dropFirst(1 + langCodeLength)
                let encoding: String.Encoding = isUTF16 ? .utf16 : .utf8
                let text = String(data: textData, encoding: encoding) ?? "[Unreadable]"

                result += text
            }
        }

        DispatchQueue.main.async {
            self.onRead?(result.isEmpty ? nil : result, nil)
            self.session?.invalidate()
        }
    }
}
