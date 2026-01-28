import SwiftUI
import SwiftData

struct FullScreenViewer: View {
    let photos: [Photo]
    let initialPhoto: Photo
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var showSimilar: Bool = false
    @State private var dragOffset: CGSize = .zero
    
    init(photos: [Photo], initialPhoto: Photo) {
        self.photos = photos
        self.initialPhoto = initialPhoto
        _currentIndex = State(initialValue: photos.firstIndex(where: { $0.id == initialPhoto.id }) ?? 0)
    }
    
    var currentPhoto: Photo? {
        guard currentIndex >= 0 && currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 主图浏览
            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    ZoomableImageView(photo: photos[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // 手势层
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // 左滑检测
                            if value.translation.width < -50 && !showSimilar {
                                withAnimation(.spring(response: 0.3)) {
                                    showSimilar = true
                                }
                            }
                            
                            // 下拉关闭
                            if value.translation.height > 0 {
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                dismiss()
                            } else {
                                withAnimation(.spring(response: 0.3)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
            
            // 关联面板 (从右侧滑入)
            if showSimilar {
                SimilarPhotoPanel(photo: currentPhoto) {
                    withAnimation(.spring(response: 0.3)) {
                        showSimilar = false
                    }
                }
                .transition(.move(edge: .trailing))
            }
            
            // 顶部控制
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    Spacer()
                    
                    // 类型标识
                    if let photo = currentPhoto {
                        HStack(spacing: 4) {
                            Image(systemName: photo.type.icon)
                                .font(.system(size: 10))
                            Text(photo.type.displayName)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(photo.type == .myWork ? .mirrorBlue : .mirrorRed)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // 底部提示
                if !showSimilar {
                    Text("← 左滑查看关联")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.bottom, 40)
                }
            }
        }
        .offset(y: dragOffset.height)
        .scaleEffect(1 - (dragOffset.height / 1000))
        .statusBarHidden()
    }
}

// MARK: - Zoomable Image

struct ZoomableImageView: View {
    let photo: Photo
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            if let imageData = photo.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1), 4)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                if scale < 1.0 {
                                    withAnimation(.spring(response: 0.3)) {
                                        scale = 1.0
                                    }
                                }
                            }
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                withAnimation(.spring(response: 0.3)) {
                                    scale = scale > 1 ? 1 : 2
                                }
                            }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

// MARK: - Similar Photo Panel

struct SimilarPhotoPanel: View {
    let photo: Photo?
    let onClose: () -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 半透明背景
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            // 面板内容
            VStack(alignment: .leading, spacing: 20) {
                // 标题
                HStack {
                    Text("镜像关联")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.mirrorYellow)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                
                // 占位内容 (AI 分析结果)
                VStack(alignment: .leading, spacing: 16) {
                    Text("正在分析视觉基因...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    // 进度条
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .overlay(
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.mirrorYellow)
                                    .frame(width: geo.size.width * 0.6)
                            }
                        )
                    
                    Text("AI 将在这里展示与当前照片\n视觉基因匹配的灵感图")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.6))
                        .lineSpacing(4)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(24)
            .frame(width: 280)
            .background(Color(white: 0.1))
            .offset(x: UIScreen.main.bounds.width - 280)
        }
    }
}

#Preview {
    FullScreenViewer(photos: [], initialPhoto: Photo())
        .modelContainer(for: Photo.self)
}
