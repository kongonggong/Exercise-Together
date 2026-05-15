import Foundation
import SwiftUI
import AVFoundation
import Vision


struct CameraViewWrapper: UIViewControllerRepresentable {
    var poseEstimator: PoseEstimator
    var recordingManager: CameraRecordingManager

    func makeUIViewController(context: Context) -> some UIViewController {
        let cvc = CameraViewController()
        cvc.delegate = poseEstimator
        cvc.recordingManager = recordingManager
        return cvc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let cameraViewController = uiViewController as? CameraViewController else { return }
        cameraViewController.recordingManager = recordingManager
    }
}
