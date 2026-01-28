# Mirror — 技术方案

**版本:** v0.1
**日期:** 2026-01-28
**作者:** Doe

---

## 1. 技术栈选择

### 1.1 平台: iOS 原生

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| **SwiftUI + Swift** | 原生性能、系统集成好、Apple 生态 | 只能 iOS | ✅ 选择 |
| Flutter | 跨平台 | 相册集成麻烦、包体积大 | ❌ |
| React Native | 跨平台、JS 生态 | 性能一般、原生桥接复杂 | ❌ |

**理由:**
- 相册 (PhotoKit) 集成最方便
- Share Extension 实现容易
- Core ML 跑 AI 模型最高效
- 思凯有 Mac,可以直接开发

### 1.2 最低支持版本
- **iOS 17.0+**
- 理由: SwiftData、新 SwiftUI 特性

---

## 2. 架构设计

### 2.1 整体架构

```
┌─────────────────────────────────────────────┐
│                    UI Layer                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────────────┐│
│  │  Home   │ │Discover │ │   FullScreen    ││
│  │  View   │ │  View   │ │     Viewer      ││
│  └────┬────┘ └────┬────┘ └───────┬─────────┘│
└───────┼──────────┼───────────────┼──────────┘
        │          │               │
┌───────┴──────────┴───────────────┴──────────┐
│              ViewModel Layer                 │
│  ┌─────────────┐ ┌─────────────────────────┐│
│  │ PhotoStore  │ │   SimilarityEngine     ││
│  └──────┬──────┘ └───────────┬─────────────┘│
└─────────┼────────────────────┼──────────────┘
          │                    │
┌─────────┴────────────────────┴──────────────┐
│               Service Layer                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│  │ PhotoKit │ │ CoreML   │ │  SwiftData   │ │
│  │ Service  │ │ Service  │ │  Repository  │ │
│  └──────────┘ └──────────┘ └──────────────┘ │
└─────────────────────────────────────────────┘
          │              │            │
    ┌─────┴─────┐  ┌─────┴────┐ ┌────┴─────┐
    │  Photos   │  │  CLIP    │ │ SwiftData│
    │  Library  │  │  Model   │ │    DB    │
    └───────────┘  └──────────┘ └──────────┘
```

### 2.2 模块职责

| 模块 | 职责 |
|------|------|
| **UI Layer** | 视图展示、手势处理 |
| **PhotoStore** | 照片数据管理、CRUD |
| **SimilarityEngine** | AI 相似度计算、关联发现 |
| **PhotoKitService** | 相册读取、权限管理 |
| **CoreMLService** | 模型加载、推理 |
| **SwiftDataRepository** | 本地数据持久化 |

---

## 3. 数据模型

### 3.1 核心模型

```swift
import SwiftData

@Model
class Photo {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var importedAt: Date
    var type: PhotoType // .myWork 或 .inspiration
    
    // 图片数据
    var imageData: Data?
    var thumbnailData: Data?
    var width: Int
    var height: Int
    
    // 来源信息
    var sourceType: SourceType // .photoLibrary, .clipboard, .url
    var sourceURL: String?
    var sourceAssetID: String? // PHAsset ID
    
    // AI 特征
    var embedding: [Float]? // CLIP embedding (512维)
    var dominantColors: [String]? // 主色调 hex
    var analyzedAt: Date?
    
    // 关联
    var similarPhotos: [SimilarityLink]?
}

enum PhotoType: String, Codable {
    case myWork = "my_work"
    case inspiration = "inspiration"
}

enum SourceType: String, Codable {
    case photoLibrary
    case clipboard
    case url
}

@Model
class SimilarityLink {
    var id: UUID
    var photoA: Photo
    var photoB: Photo
    var overallScore: Float // 0-1
    var compositionScore: Float?
    var colorScore: Float?
    var createdAt: Date
}
```

### 3.2 存储策略

| 数据 | 存储位置 | 理由 |
|------|---------|------|
| 原图 | App 沙盒 Documents | 保证质量、离线可用 |
| 缩略图 | App 沙盒 Caches | 快速加载、可重建 |
| 元数据 | SwiftData | 结构化查询 |
| Embedding | SwiftData | 随元数据存储 |

---

## 4. AI 相似度方案

### 4.1 模型选择

| 模型 | 大小 | 特点 | 结论 |
|------|------|------|------|
| **CLIP ViT-B/32** | ~150MB | 通用视觉特征、效果好 | ✅ 推荐 |
| MobileNetV3 | ~20MB | 轻量但特征弱 | ❌ |
| ResNet50 | ~100MB | 经典但不如CLIP | ❌ |

### 4.2 实现流程

```
[导入照片]
    ↓
[预处理: 缩放到 224x224, 归一化]
    ↓
[Core ML 推理: CLIP 模型]
    ↓
[输出: 512维 embedding 向量]
    ↓
[存储到 SwiftData]
    ↓
[计算与已有照片的余弦相似度]
    ↓
[相似度 > 阈值 → 创建 SimilarityLink]
```

### 4.3 相似度计算

```swift
func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    let dotProduct = zip(a, b).map(*).reduce(0, +)
    let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
    let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
    return dotProduct / (normA * normB)
}

// 阈值设定
let highSimilarity: Float = 0.85  // 非常相似
let mediumSimilarity: Float = 0.70  // 有关联
let lowSimilarity: Float = 0.55  // 可能相关
```

### 4.4 性能优化

- **批量处理:** 导入多张时批量推理
- **后台队列:** AI 分析不阻塞 UI
- **增量计算:** 新照片只与已有照片比较
- **缓存:** Embedding 只算一次

---

## 5. 核心功能实现

### 5.1 从相册导入

```swift
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // 无限制
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
}
```

### 5.2 从剪贴板导入

```swift
func importFromClipboard() -> UIImage? {
    if UIPasteboard.general.hasImages {
        return UIPasteboard.general.image
    }
    return nil
}
```

### 5.3 黄斑对焦动效

```swift
struct RangefinderEffect: View {
    @State private var offset: CGFloat = 20
    @State private var opacity: Double = 0.5
    
    var body: some View {
        ZStack {
            // 左侧影像
            Image(uiImage: image)
                .offset(x: -offset)
                .opacity(opacity)
            
            // 右侧影像
            Image(uiImage: image)
                .offset(x: offset)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                offset = 0
                opacity = 1.0
            }
        }
    }
}
```

### 5.4 全屏浏览

```swift
struct FullScreenViewer: View {
    @State var currentIndex: Int
    let photos: [Photo]
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(photos.indices, id: \.self) { index in
                ZoomableImage(photo: photos[index])
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color.black)
        .ignoresSafeArea()
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        // 左滑 → 显示关联照片
                        showSimilarPhotos()
                    }
                }
        )
    }
}
```

---

## 6. 项目结构

```
Mirror/
├── MirrorApp.swift              # App 入口
├── ContentView.swift            # 主视图
│
├── Models/
│   ├── Photo.swift              # 照片模型
│   └── SimilarityLink.swift     # 关联模型
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift       # 首页
│   │   └── PhotoGrid.swift      # 瀑布流
│   ├── Discover/
│   │   ├── DiscoverView.swift   # 发现页
│   │   └── SimilarityCard.swift # 关联卡片
│   ├── Viewer/
│   │   ├── FullScreenViewer.swift
│   │   └── ZoomableImage.swift
│   ├── Import/
│   │   ├── ImportSheet.swift
│   │   └── RangefinderEffect.swift
│   └── Components/
│       ├── PhotoThumbnail.swift
│       └── TabBar.swift
│
├── ViewModels/
│   ├── PhotoStore.swift         # 照片数据管理
│   └── SimilarityEngine.swift   # AI 相似度引擎
│
├── Services/
│   ├── PhotoKitService.swift    # 相册服务
│   ├── CoreMLService.swift      # AI 推理服务
│   └── ClipboardService.swift   # 剪贴板服务
│
├── Resources/
│   ├── CLIP.mlmodel             # Core ML 模型
│   └── Assets.xcassets          # 图片资源
│
└── Utilities/
    ├── Extensions.swift
    └── Constants.swift
```

---

## 7. 开发计划

### 7.1 Phase 1: 基础框架 (Day 1-2)
- [ ] 创建 Xcode 项目
- [ ] 设置 SwiftData 模型
- [ ] 实现相册导入
- [ ] 实现剪贴板导入
- [ ] 基础 UI 框架

### 7.2 Phase 2: 核心体验 (Day 3-5)
- [ ] 瀑布流首页
- [ ] 全屏浏览器
- [ ] 黄斑对焦动效
- [ ] 深色模式

### 7.3 Phase 3: AI 功能 (Day 6-8)
- [ ] 集成 CLIP 模型
- [ ] Embedding 提取
- [ ] 相似度计算
- [ ] 关联发现 UI

### 7.4 Phase 4: 打磨 (Day 9-10)
- [ ] 动画优化
- [ ] 性能优化
- [ ] Bug 修复
- [ ] TestFlight

---

## 8. 风险与应对

| 风险 | 影响 | 应对 |
|------|------|------|
| CLIP 模型太大 | 安装包体积 | 首次启动下载 / 量化模型 |
| AI 推理慢 | 用户体验差 | 后台处理 + 进度提示 |
| 相似度不准 | 核心功能失效 | 调整阈值 + 多维度评分 |
| iOS 17 限制用户群 | 用户量少 | 后续支持 iOS 16 |

---

## 9. 依赖项

### 9.1 系统框架
- SwiftUI
- SwiftData
- PhotosUI (PHPickerViewController)
- CoreML
- Vision (可选,用于构图分析)

### 9.2 第三方库
- 暂无 (尽量原生实现)

### 9.3 资源
- CLIP ViT-B/32 Core ML 模型
  - 来源: Hugging Face 转换
  - 或: Apple 的 MobileViT

---

## 10. 下一步

1. ✅ 技术方案完成
2. ⏳ 初始化 Xcode 项目
3. ⏳ 获取/转换 CLIP 模型
4. ⏳ 实现基础导入功能
5. ⏳ 实现 AI 相似度计算

---

*文档版本: 0.1 | 最后更新: 2026-01-28 02:30*
