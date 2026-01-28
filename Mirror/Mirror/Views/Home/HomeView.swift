import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Photo.importedAt, order: .reverse) private var photos: [Photo]
    @State private var selectedPhoto: Photo?
    @State private var filterType: FilterType = .all
    
    enum FilterType: String, CaseIterable {
        case all = "全部"
        case myWork = "作品"
        case inspiration = "灵感"
    }
    
    var filteredPhotos: [Photo] {
        switch filterType {
        case .all:
            return photos
        case .myWork:
            return photos.filter { $0.type == .myWork }
        case .inspiration:
            return photos.filter { $0.type == .inspiration }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Mirror")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Filter Pills
                HStack(spacing: 8) {
                    ForEach(FilterType.allCases, id: \.self) { type in
                        FilterPill(
                            title: type.rawValue,
                            isSelected: filterType == type,
                            icon: type == .myWork ? "camera.fill" : (type == .inspiration ? "star.fill" : nil)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                filterType = type
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Photo Grid
                if filteredPhotos.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        MasonryGrid(photos: filteredPhotos) { photo in
                            selectedPhoto = photo
                        }
                        .padding(.horizontal, 2)
                        .padding(.bottom, 100) // Tab bar space
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            FullScreenViewer(
                photos: filteredPhotos,
                initialPhoto: photo
            )
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let icon: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.mirrorYellow : Color.white.opacity(0.1))
            )
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("还没有照片")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            Text("点击下方 + 添加你的第一张照片")
                .font(.system(size: 13))
                .foregroundColor(.gray.opacity(0.7))
            
            Spacer()
        }
    }
}

// MARK: - Masonry Grid

struct MasonryGrid: View {
    let photos: [Photo]
    let onTap: (Photo) -> Void
    
    // 简单的双列布局
    var leftColumn: [Photo] {
        photos.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
    }
    
    var rightColumn: [Photo] {
        photos.enumerated().filter { $0.offset % 2 == 1 }.map { $0.element }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // 左列
            LazyVStack(spacing: 4) {
                ForEach(leftColumn) { photo in
                    PhotoThumbnail(photo: photo) {
                        onTap(photo)
                    }
                }
            }
            
            // 右列
            LazyVStack(spacing: 4) {
                ForEach(rightColumn) { photo in
                    PhotoThumbnail(photo: photo) {
                        onTap(photo)
                    }
                }
            }
        }
    }
}

// MARK: - Photo Thumbnail

struct PhotoThumbnail: View {
    let photo: Photo
    let onTap: () -> Void
    
    var aspectRatio: CGFloat {
        guard photo.width > 0, photo.height > 0 else { return 1.0 }
        return CGFloat(photo.width) / CGFloat(photo.height)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // 照片
                if let thumbnailData = photo.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .aspectRatio(aspectRatio, contentMode: .fit)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(aspectRatio, contentMode: .fit)
                }
                
                // 类型标识
                Image(systemName: photo.type.icon)
                    .font(.system(size: 10))
                    .foregroundColor(photo.type == .myWork ? .mirrorBlue : .mirrorRed)
                    .padding(6)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Photo.self)
}
