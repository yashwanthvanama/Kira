//
//  SpeechRecognizerManager.swift
//  Kira
//
//  Created by Yashwanth Vanama on 12/28/24.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognizerManager: ObservableObject {
    @Published var commandText = "Press the button to speak a command."
    
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.commandText = "Speech recognition is ready."
                case .denied:
                    self.commandText = "Speech recognition permission denied."
                case .restricted, .notDetermined:
                    self.commandText = "Speech recognition is not available."
                @unknown default:
                    self.commandText = "An unknown error occurred."
                }
            }
        }
    }
    func startListening() {
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                fatalError("Unable to create recognition request.")
            }

            let inputNode = audioEngine.inputNode
            recognitionRequest.shouldReportPartialResults = true

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    DispatchQueue.main.async {
                        self.commandText = result.bestTranscription.formattedString
                    }
                }
                if let error = error {
                    print("Error recognizing speech: \(error.localizedDescription)")
                    self.stopListening()
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.commandText = "Listening for commands..."
            }
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
            stopListening()
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        DispatchQueue.main.async {
            self.commandText = "Press the button to speak a command."
        }
    }
}
