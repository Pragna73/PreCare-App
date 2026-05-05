import SwiftUI
import UniformTypeIdentifiers
import UIKit

@available(iOS 16.0, *)
struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()

    // MARK: - Upload State
    @State private var selectedFileURL: URL?
    @State private var showFilePicker = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showUploadOptions = false
    @State private var goToResult = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {

                // MARK: - Header
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color(hex: "#FF2D6F"))

                    Text("Precare")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }

                // MARK: - AI Health Analysis Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("AI Health Analysis")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Upload your medical reports for instant AI analysis and personalized health insights.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: - Upload Card
                uploadCard

                // MARK: - Start Analysis Button
                PrimaryButton(title: vm.isLoading ? "Analyzing..." : "Start Analysis") {
                    startAnalysis()
                }
                .disabled(!hasUploadedFile || vm.isLoading)
                .opacity(!hasUploadedFile ? 0.6 : 1)

                if let report = vm.latestReport {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Latest report ID: \(report.id)")
                            .font(.footnote)
                            .foregroundColor(.gray)

                        if let status = report.status {
                            Text("Status: \(status)")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }

                        if let risk = report.riskLevel {
                            Text("Risk: \(risk)")
                                .font(.footnote)
                                .foregroundColor(riskColor(risk))
                        }

                        if let score = report.riskScore {
                            Text("Risk score: \(String(format: "%.2f", score))")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }

                        Text(report.requiresConfirmation ? "Confirmation required" : "No confirmation required")
                            .font(.footnote)
                            .foregroundColor(report.requiresConfirmation ? .orange : .green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if vm.emergencyStatus.lowercased() != "no active emergency" {
                    CardView {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Emergency Status")
                                    .font(.headline)
                                Text(vm.emergencyStatus)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }

                statusCards

                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                if vm.latestReport?.requiresConfirmation == true {
                    PrimaryButton(title: "Confirm Action") {
                        Task {
                            await vm.confirmLatestReport()
                        }
                    }
                }

                if !vm.dashboardMessage.isEmpty {
                    Text(vm.dashboardMessage)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // MARK: - Quick Actions
                HStack(spacing: 16) {

                    NavigationLink(destination: HealthTrackingView()) {
                        DashboardActionCard(
                            title: "Health Tracking",
                            subtitle: "Monitor metrics & trends",
                            action: "View",
                            icon: "heart.fill"
                        )
                    }

                    NavigationLink(destination: AskMayaView()) {
                        DashboardActionCard(
                            title: "Ask Maya",
                            subtitle: "24/7 AI assistant",
                            action: "Chat",
                            icon: "message.fill"
                        )
                    }
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)

        // MARK: - Navigation
        .navigationDestination(isPresented: $goToResult) {
            AnalysisResultView(severity: vm.latestSeverity, report: vm.latestReport)
        }
        .task {
            await vm.loadDashboard()
        }

        // MARK: - PDF Picker
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .plainText, .image]
        ) { result in
            if case .success(let url) = result {
                selectedFileURL = url
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSource) { image in
                if let image {
                    selectedFileURL = saveImageToTemporaryFile(image: image)
                }
            }
        }
        .confirmationDialog("Upload Report", isPresented: $showUploadOptions, titleVisibility: .visible) {
            Button("Capture with Camera") {
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    vm.errorMessage = "Camera is not available on this device."
                    return
                }
                imagePickerSource = .camera
                showImagePicker = true
            }
            Button("Pick from Photos") {
                imagePickerSource = .photoLibrary
                showImagePicker = true
            }
            Button("Pick PDF / File") { showFilePicker = true }
            Button("Cancel", role: .cancel) {}
        }
    }
}


@available(iOS 16.0, *)
private extension DashboardView {

    var uploadCard: some View {
        VStack(spacing: 14) {

            if vm.isLoading {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(Color(hex: "#FF2D6F"))

                Text("Analyzing your report…")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .transition(.opacity)
            } else {
                Image(systemName: "arrow.up.doc")
                    .font(.system(size: 34))
                    .foregroundColor(Color(hex: "#FF2D6F"))

                Text(uploadedFileName)
                    .font(.body)
                    .fontWeight(.medium)

                Text("PDF, JPG, PNG • Max 10MB")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3))
        )
        .onTapGesture {
            presentUploadOptions()
        }
        .animation(.easeInOut, value: vm.isLoading)
    }
}


private extension DashboardView {

    var hasUploadedFile: Bool {
        selectedFileURL != nil
    }

    var uploadedFileName: String {
        if let file = selectedFileURL {
            return file.lastPathComponent
        }
        return "Drop your file here or click to browse"
    }

    func presentUploadOptions() {
        showUploadOptions = true
    }

    func startAnalysis() {
        guard let selectedFileURL else { return }

        Task {
            let canAccess = selectedFileURL.startAccessingSecurityScopedResource()
            defer {
                if canAccess {
                    selectedFileURL.stopAccessingSecurityScopedResource()
                }
            }

            let didUpload = await vm.uploadAndFetchReport(fileURL: selectedFileURL, patientName: nil)
            if didUpload {
                goToResult = true
            }
        }
    }

    var statusCards: some View {
        HStack(spacing: 12) {
            statusCard(
                title: "AI Status",
                value: vm.latestRiskLevel,
                color: riskColor(vm.latestRiskLevel)
            )
            statusCard(
                title: "Appointments",
                value: vm.nextAppointment,
                color: .blue
            )
        }
    }

    func statusCard(title: String, value: String, color: Color) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func saveImageToTemporaryFile(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            return nil
        }
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("report-\(UUID().uuidString).jpg")
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            vm.errorMessage = error.localizedDescription
            return nil
        }
    }

    func riskColor(_ risk: String) -> Color {
        switch risk.uppercased() {
        case "DANGER":
            return .red
        case "MODERATE", "WARNING":
            return .orange
        case "FINE", "GOOD":
            return .green
        default:
            return .gray
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage?) -> Void

        init(onImagePicked: @escaping (UIImage?) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onImagePicked(nil)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            picker.dismiss(animated: true)
            let image = info[.originalImage] as? UIImage
            onImagePicked(image)
        }
    }
}
