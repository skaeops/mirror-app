import SwiftUI
import SwiftData

struct DiscoverView: View {
    @Query private var photos: [Photo]
    @Query private var links: [SimilarityLink]
    
    var myWorks: [Photo] {
        photos.filter { $0.type == .myWork }
    }
    
    var inspirations: [Photo] {
        photos.filter { $0.type == .inspiration }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.mirrorYellow)
                        Text("发现")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    if photos.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            Spacer(minLength: 100)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.3))
                            
                            Text("等待发现共鸣")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("添加更多照片后\nAI 将为你发现隐藏的视觉关联")
                                .font(.system(size: 13))
                                .foregroundColor(.gray.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            
                            Spacer(minLength: 100)
                        }
                        .frame(maxWidth: .infinity)
                    } else if links.isEmpty {
                        // 有照片但还没有发现关联
                        VStack(spacing: 20) {
                            // 统计卡片
                            HStack(spacing: 16) {
                                StatCard(
                                    title: "作品",
                                    count: myWorks.count,
                                    icon: "camera.fill",
                                    color: .mirrorBlue
                                )
                                
                                StatCard(
                                    title: "灵感",
                                    count: inspirations.count,
                                    icon: "star.fill",
                                    color: .mirrorRed
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // 提示
                            VStack(spacing: 12) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 32))
                                    .foregroundColor(.mirrorYellow.opacity(0.5))
                                
                                Text("AI 正在学习你的视觉偏好")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("继续添加照片，当作品与灵感产生\n"不期而遇的共鸣"时，你会收到通知")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                            }
                            .padding(.vertical, 40)
                        }
                    } else {
                        // 有关联时显示
                        ForEach(links) { link in
                            SimilarityCard(link: link, photos: photos)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.gray)
            }
            .font(.system(size: 13))
            
            Text("\(count)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Similarity Card

struct SimilarityCard: View {
    let link: SimilarityLink
    let photos: [Photo]
    
    var photoA: Photo? {
        photos.first { $0.id == link.photoAId }
    }
    
    var photoB: Photo? {
        photos.first { $0.id == link.photoBId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text("镜像共鸣")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.mirrorYellow)
                
                Spacer()
                
                Text("\(Int(link.overallScore * 100))%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // 双图对比
            HStack(spacing: 8) {
                // Photo A
                if let photo = photoA,
                   let data = photo.thumbnailData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(8)
                }
                
                // 连接线
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(.mirrorYellow)
                    .font(.system(size: 12))
                
                // Photo B
                if let photo = photoB,
                   let data = photo.thumbnailData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(8)
                }
            }
            
            // AI 分析
            if let description = link.description {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    DiscoverView()
        .modelContainer(for: [Photo.self, SimilarityLink.self])
}
