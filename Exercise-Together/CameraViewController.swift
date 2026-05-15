import Foundation
import UIKit
import AVFoundation
import Vision
import SwiftUI

final class CameraViewController: UIViewController {
    private var cameraSession: AVCaptureSession?
    var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    var recordingManager: CameraRecordingManager?
    private let cameraQueue = DispatchQueue(label: "CameraOutput", qos: .userInteractive)
    private let movieOutput = AVCaptureMovieFileOutput()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // --- ส่วนที่เพิ่มเข้ามา: เช็กสิทธิ์ทันทีที่โหลดหน้าจอ ---
        checkCameraPermissions()
        // --------------------------------------------------
    }

    override func loadView() {
        view = CameraView()
    }

    private var cameraView: CameraView { view as! CameraView }

    override func viewWillDisappear(_ animated: Bool) {
        // หยุด session เมื่อปิดหน้าจอ
        recordingManager?.stopRecording()
        if let session = cameraSession, session.isRunning {
            session.stopRunning()
        }
        super.viewWillDisappear(animated)
    }

    // --- ส่วนที่เพิ่มเข้ามา: ฟังก์ชันตรวจสอบสิทธิ์แบบละเอียด ---
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // ขออนุญาตครั้งแรก
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCameraSession()
                    }
                }
            }
        case .authorized:
            // ได้รับอนุญาตแล้ว
            setupCameraSession()
        case .denied, .restricted:
            print("Camera access denied. Please enable it in Settings.")
        @unknown default:
            break
        }
    }
    // ----------------------------------------------------

    private func setupCameraSession() {
        // ป้องกันการสร้าง session ซ้อนกัน
        guard cameraSession == nil else { return }
        
        do {
            try prepareAVSession()
            cameraView.previewLayer.session = cameraSession
            cameraView.previewLayer.videoGravity = .resizeAspectFill
            adjustPreviewLayerOrientation()
            
            // เริ่มการทำงานใน Background Thread เพื่อไม่ให้ UI ค้าง
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.cameraSession?.startRunning()
                DispatchQueue.main.async {
                    self?.recordingManager?.startRecordingIfPending()
                }
            }
        } catch {
            print("Setup Error: \(error.localizedDescription)")
        }
    }

    @objc func orientationDidChange() {
        adjustPreviewLayerOrientation()
    }

    private func adjustPreviewLayerOrientation() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let connection = self.cameraView.previewLayer.connection else { return }
            let angle = self.videoRotationAngle()
            guard connection.isVideoRotationAngleSupported(angle) else { return }
            connection.videoRotationAngle = angle
            if let recordingConnection = self.movieOutput.connection(with: .video),
               recordingConnection.isVideoRotationAngleSupported(angle) {
                recordingConnection.videoRotationAngle = angle
            }
            self.cameraView.previewLayer.frame = self.view.bounds
        }
    }

    private func videoRotationAngle() -> CGFloat {
        let interfaceOrientation = view.window?.windowScene?.interfaceOrientation ?? .portrait
        switch interfaceOrientation {
        case .portrait: return 90
        case .landscapeRight: return 180
        case .portraitUpsideDown: return 270
        case .landscapeLeft: return 0
        default: return 90
        }
    }

    func prepareAVSession() throws {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high

        // เลือกกล้องหน้า
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }

        let deviceInput = try AVCaptureDeviceInput(device: videoDevice)
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            dataOutput.setSampleBufferDelegate(delegate, queue: cameraQueue)
        }

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            recordingManager?.attach(movieOutput: movieOutput)
        }
        
        session.commitConfiguration()
        cameraSession = session
    }
}
