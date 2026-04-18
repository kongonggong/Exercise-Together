import AVFoundation
import SwiftUI
import Combine

class VideoProcessor: ObservableObject {
    var player: AVPlayer?
    var videoOutput: AVPlayerItemVideoOutput?
    var displayLink: CADisplayLink?
    weak var poseEstimator: PoseEstimator?
    
    func loadVideo(url: URL, poseEstimator: PoseEstimator) {
        self.poseEstimator = poseEstimator
        let playerItem = AVPlayerItem(url: url)
        
        let pixelBufferAttributes = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
        playerItem.add(videoOutput!)
        
        self.player = AVPlayer(playerItem: playerItem)
        
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func play() {
        player?.play()
    }
    
    func stop() {
        player?.pause()
        displayLink?.invalidate()
    }
    
    @objc func displayLinkFired(link: CADisplayLink) {
        guard let output = videoOutput, let itemTime = player?.currentTime() else { return }
        
        if output.hasNewPixelBuffer(forItemTime: itemTime) {
            var presentationTime = CMTime.zero
            if let pixelBuffer = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: &presentationTime) {
                var sampleBuffer: CMSampleBuffer?
                var timingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: itemTime, decodeTimeStamp: .invalid)
                var formatDescription: CMVideoFormatDescription?
                CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
                
                if let fd = formatDescription {
                    CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescription: fd, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
                }
                
                if let sb = sampleBuffer {
                    // Assuming portrait recording. More robust code would check AVAssetTrack preferredTransform
                    poseEstimator?.processFrame(sb, orientation: .up)
                }
            }
        }
    }
}
