//
//  ContentView.swift
//  Kira
//
//  Created by Yashwanth Vanama on 12/26/24.
//

import SwiftUI
import Speech

struct ContentView: View {
    @State private var commandText = "Press the button and speak a command."
    @State private var isListening = false
    
    let speechRecognizer = SFSpeechRecognizer()
    let audioEngine = AVAudioEngine()
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?

    var body: some View {
        VStack {
            Text(commandText)
                .font(.headline)
                .padding()
                .multilineTextAlignment(.center)

            Button(action: {
                if isListening {
                    stopListening()
                } else {
                    startListening()
                }
                isListening.toggle()
            }) {
                Text(isListening ? "Stop Listening" : "Start Listening")
                    .padding()
                    .foregroundColor(.white)
                    .background(isListening ? Color.red : Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .onAppear {
            requestSpeechAuthorization()
        }
    }
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized.")
            case .denied:
                commandText = "Speech recognition permission denied."
            case .restricted, .notDetermined:
                commandText = "Speech recognition not available."
            @unknown default:
                commandText = "Unknown speech recognition error."
            }
        }
    }
    func startListening() {
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            let inputNode = audioEngine.inputNode
            
            guard let recognitionRequest = recognitionRequest else {
                fatalError("Unable to create recognition request.")
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    commandText = result.bestTranscription.formattedString
                }
                if let error = error {
                    print("Error recognizing speech: \(error.localizedDescription)")
                    stopListening()
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            commandText = "Listening for commands..."
            catch {
                print("Error starting audio engine: \(error.localizedDescription)")
                stopListening()
            }
        }
    }
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        commandText = "Press the button to speak a command."
    }
}
