import AVFoundation
import Foundation
import Photos

final class CameraRecordingManager: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var isSavingToPhotos = false
    @Published var latestSavedVideoURL: URL?
    @Published var saveMessage: String?

    private weak var movieOutput: AVCaptureMovieFileOutput?
    private var pendingStart = false
    private var activeRecordingURL: URL?

    func attach(movieOutput: AVCaptureMovieFileOutput) {
        self.movieOutput = movieOutput
    }

    func startRecordingIfPending() {
        guard pendingStart else { return }
        startRecording()
    }

    func startRecording() {
        pendingStart = true

        guard let movieOutput, !movieOutput.isRecording else { return }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("form-analysis-\(UUID().uuidString)")
            .appendingPathExtension("mov")

        activeRecordingURL = outputURL
        saveMessage = nil
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
    }

    func stopRecording() {
        pendingStart = false

        guard let movieOutput, movieOutput.isRecording else { return }
        movieOutput.stopRecording()
    }
}

extension CameraRecordingManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        DispatchQueue.main.async {
            self.isRecording = true
            self.saveMessage = "Recording analysis video"
        }
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isRecording = false
        }

        guard error == nil else {
            DispatchQueue.main.async {
                self.saveMessage = "Recording failed"
            }
            return
        }

        saveVideoToPhotoLibrary(outputFileURL)
    }

    private func saveVideoToPhotoLibrary(_ url: URL) {
        DispatchQueue.main.async {
            self.isSavingToPhotos = true
            self.saveMessage = "Saving to Photos"
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.isSavingToPhotos = false
                    self.saveMessage = "Photos permission needed"
                }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    self.isSavingToPhotos = false
                    self.latestSavedVideoURL = success ? url : nil
                    self.saveMessage = success ? "Saved to Photos" : "Could not save to Photos"
                }
            }
        }
    }
}
