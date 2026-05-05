import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct UploadReportView: View {
    @StateObject private var vm = DashboardViewModel()

    @State private var selectedFileURL: URL?
    @State private var showFilePicker = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showUploadOptions = false
    @State private var navigateToResult = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upload Pregnancy Report")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Camera, gallery, or file upload (PDF/Image/TXT).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardView {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 34))
                            .foregroundColor(Color(hex: "#FF2D6F"))

                        Text(selectedFileURL?.lastPathComponent ?? "Tap to choose report file")
                            .font(.subheadline)

                        Text("Supports medical pregnancy reports only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .onTapGesture { showUploadOptions = true }

                if vm.isLoading {
                    ProgressView("Uploading and processing...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(title: vm.isLoading ? "Processing..." : "Upload & Analyze") {
                    startUpload()
                }
                .disabled(selectedFileURL == nil || vm.isLoading)
                .opacity(selectedFileURL == nil ? 0.65 : 1)

                if let report = vm.latestReport {
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Latest Upload")
                                .font(.headline)
                            Text("Report ID: \(report.id)")
                                .font(.footnote)
                            Text("Risk: \(report.riskLevel ?? "Unknown")")
                                .font(.footnote)
                                .foregroundColor(riskColor(report.riskLevel))
                            if let recommendation = report.recommendation {
                                Text(recommendation)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Upload Report")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResult) {
            AnalysisResultView(severity: vm.latestSeverity, report: vm.latestReport)
        }
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

    private func startUpload() {
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
                navigateToResult = true
            }
        }
    }

    private func saveImageToTemporaryFile(image: UIImage) -> URL? {
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

    private func riskColor(_ risk: String?) -> Color {
        switch (risk ?? "").uppercased() {
        case "GOOD", "FINE":
            return .green
        case "WARNING", "MODERATE":
            return .orange
        case "DANGER":
            return .red
        default:
            return .gray
        }
    }
}
