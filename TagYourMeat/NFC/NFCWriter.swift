//
//  NFCWriter.swift
//  TagYourMeat
//
//  Created by Jack Rogers on 6/6/25.
//

import CoreNFC

class NFCWriter: NSObject {
    private var session: NFCNDEFReaderSession?
    private var payloadText: String = ""
    private var completion: ((Bool, Error?) -> Void)?

    func beginWriting(payload: String, completion: @escaping (Bool, Error?) -> Void) {
        self.payloadText = payload
        self.completion = completion
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near the NFC tag to write."
        session?.begin()
    }
}

extension NFCWriter: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        completion?(false, error)
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag detected.")
            completion?(false, nil)
            return
        }

        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Failed to connect to tag.")
                self.completion?(false, error)
                return
            }

            guard let payload = NFCNDEFPayload.wellKnownTypeTextPayload(string: self.payloadText, locale: .current) else {
                session.invalidate(errorMessage: "Invalid payload.")
                self.completion?(false, nil)
                return
            }

            let message = NFCNDEFMessage(records: [payload])

            tag.queryNDEFStatus { status, _, error in
                if let error = error {
                    session.invalidate(errorMessage: "Error checking tag status.")
                    self.completion?(false, error)
                    return
                }

                if status == .readWrite {
                    tag.writeNDEF(message) { error in
                        if let error = error {
                            session.invalidate(errorMessage: "Failed to write tag.")
                            self.completion?(false, error)
                        } else {
                            session.alertMessage = "Tag written successfully."
                            session.invalidate()
                            self.completion?(true, nil)
                        }
                    }
                } else {
                    session.invalidate(errorMessage: "Tag is not writable.")
                    self.completion?(false, nil)
                }
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) { }
}
