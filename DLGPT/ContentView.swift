import SwiftUI
import Speech
import AVFoundation

struct ContentView: View {
    @State private var isListening = false
    @State private var recognizedText = "Your conversation with ChatGPT will appear here..."
    
    let speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    init() {
        requestSpeechAuthorization()
    }
    
    var body: some View {
        VStack {
            Text("DLGPT Chat")
                .font(.largeTitle)
                .padding()
            ScrollView {
                Text(recognizedText)
                    .padding()
            }
            .frame(height: 300) // Adjust the height as needed
            // Button
            Button(action: {
                if isListening {
                    stopListening()
                } else {
                    startListening()
                }
                isListening.toggle()
            }) {
                HStack {
                    Spacer()
                    Image(systemName: isListening ? "mic.slash.fill" : "mic.fill")
                    Text(isListening ? "Stop talking" : "Start talking")
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding()
    }
    
    // Requesting and checking authorization for speech recognition
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // Ensure the UI updates are on the main thread
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition authorization denied")
                case .restricted:
                    print("Not available on this device")
                case .notDetermined:
                    print("Not determined")
                @unknown default:
                    print("Unknown authorization status")
                }
            }
        }
    }
    
    func startListening() {
        print("Starting to listen")
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode  // Directly use the inputNode
        recognitionRequest?.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                    print("Recognized text: \(self.recognizedText)")
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                print("Stopping due to final result or error: \(String(describing: error))")
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isListening = false
                    // Call the function to fetch the response from OpenAI with the recognized text
                    self.fetchResponseFromOpenAI(for: self.recognizedText)

                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine couldn't start because of an error.")
        }
    }
    
    func stopListening() {
        print("Manually stopping listening.")
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        DispatchQueue.main.async {
            isListening = false
        }
    }
    
    func fetchResponseFromOpenAI(for text: String) {
        print("Starting request to OpenAI with text: \(text)")
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "DefaultAPIKey"
        let urlString = "https://api.openai.com/v1/chat/completions"
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                    ["role": "user", "content": text]
                ],
            //"prompt": text,
            "max_tokens": 150
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Failed to serialize data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) {data, response, error in
            if let error = error {
                print("Error making request: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("OpenAI API response status: \(httpResponse.statusCode)")
            }
            if let data = data {
                let rawResponseString = String(data: data, encoding: .utf8) ?? "Invalid data encoding"
                print("Received raw data: \(rawResponseString)")
            } else {
                print("No data received")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let answers = jsonObject["choices"] as? [[String: Any]],
                   let firstAnswer = answers.first,
                   let textResponse = firstAnswer["text"] as? String {
                    DispatchQueue.main.async {
                        // Update app's state with the new text here
                        self.recognizedText += "\n\n\(textResponse.trimmingCharacters(in: .whitespacesAndNewlines))"
                        print("Received response from OpenAI: \(textResponse)")
                        
                        self.speak(text: textResponse.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }.resume()
    }
    
    func speak(text: String) {
        let utterance  = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        print("Speaking: \(text)")
    }
    
}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
