import SwiftUI

struct PostWorkoutSummaryView: View {
    @Environment(\.dismiss) var dismiss
    
    let totalReps: Int
    let formScore: Double
    let caloriesBurned: Double
    let onReset: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Workout Complete")
                .font(.system(size: 32, weight: .black))
                .padding(.top, 40)
            
            VStack(spacing: 24) {
                SummaryRow(title: "Total Reps", value: "\(totalReps)", icon: "figure.run")
                SummaryRow(title: "Calories Burned", value: String(format: "%.1f kcal", caloriesBurned), icon: "flame.fill")
                SummaryRow(title: "Form Score", value: "\(Int(formScore * 100))%", icon: "checkmark.seal.fill")
            }
            .padding()
            .background(Color.primary.opacity(0.1))
            .cornerRadius(16)
            
            Spacer()
            
            Button(action: {
                onReset()
                dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.bottom, 40)
        }
        .padding()
    }
}

private struct SummaryRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 32)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.title2)
                .bold()
        }
    }
}
