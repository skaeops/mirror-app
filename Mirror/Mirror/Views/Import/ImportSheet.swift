import SwiftUI

struct ImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var showRangefinder = false
    @State private var selectedType: PhotoType = .myWork
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if showRangefinder, let image = selectedImage {
                    // 黄斑对焦界面
                    RangefinderEffect(image: image) {
                        savePhoto(image: image, type: selectedType)
                        dismiss()
                    }
                } else {
                    // 选择界面
                    VStack(spacing: 32) {
                        Spacer()
                        
                        Text("添加照片")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("选择照片类型")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        // 类型选择
                        HStack(spacing: 16) {
                            TypeButton(
                                type: .myWork,
                                isSelected: selectedType == .myWork
                            ) {
                                selectedType = .myWork
                            }
                            
                            TypeButton(
                                type: .inspiration,
                                isSelected: selectedType == .inspiration
                            ) {
                                selectedType = .inspiration
                            }
                        }
                        
                        Spacer()
                        
                        // 导入按钮
                        VStack(spacing: 16) {
                            // 从相册
                            Button {
                                showPhotoPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("从相册选择")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.mirrorYellow)
                                .cornerRadius(12)
                            }
                            
                            // 从剪贴板
                            Button {
                                importFromClipboard()
                            } label: {
                                HStack {
                                    Image(systemName: "doc.on.clipboard")
                                    Text("从剪贴板粘贴")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedImage) { _, newImage in
                if newImage != nil {
                    withAnimation {
                        showRangefinder = true
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func importFromClipboard() {
        if UIPasteboard.general.hasImages,
           let image = UIPasteboard.general.image {
            selectedImage = image
        }
    }
    
    private func savePhoto(image: UIImage, type: PhotoType) {
        let photo = Photo(
            type: type,
            imageData: image.jpegData(compressionQuality: 0.9),
            thumbnailData: image.preparingThumbnail(of: CGSize(width: 400, height: 400))?.jpegData(compressionQuality: 0.8),
            width: Int(image.size.width),
            height: Int(image.size.height),
            sourceType: .photoLibrary
        )
        modelContext.insert(photo)
    }
}

// MARK: - Type Button

struct TypeButton: View {
    let type: PhotoType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .mirrorYellow : .gray)
                
                Text(type.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(width: 120, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.mirrorYellow : Color.gray.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.mirrorYellow.opacity(0.1) : Color.clear)
                    )
            )
        }
    }
}

// MARK: - Photo Picker

import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

#Preview {
    ImportSheet()
}
