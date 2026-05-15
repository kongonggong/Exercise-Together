//
//  VideoDetailView.swift
//  Exercise-Together
//
//  Created by Sanpon Soontornnon on 15/5/2569 BE.
//

import SwiftUI
import AVKit

struct VideoDetailView: View {

    let video: CDExerciseVideo

    var body: some View {

        VStack {

            if let videoName = video.videoName,
               let path = Bundle.main.path(
                    forResource: videoName,
                    ofType: "mp4"
               ) {

                let url = URL(fileURLWithPath: path)

                VideoPlayer(
                    player: AVPlayer(url: url)
                )
                .frame(height: 300)

            } else {

                Text("Video not found")
            }

            Text(video.title ?? "")
                .font(.title2)
                .bold()
                .padding(.top)

            Text(video.category ?? "")
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
