import SwiftUI

/// 黄斑对焦效果 - 模拟徕卡 M 系列取景器的联动对焦体验
/// 用户需要滑动让两个错位的影像重合，才能完成照片导入
struct RangefinderEffect: View {
    let image: UIImage
    let onFocused: () -> Void
    
    @State private var sliderValue: Double = 0.3 // 初始错位
    @State private var isFocused: Bool = false
    @State private var showSuccess: Bool = false
    
    // 对焦阈值
    private let focusThreshold: Double = 0.02
    
    var body: some View {
        ZStack {
            // 纯黑背景
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // 标题
                Text("对焦冲洗")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                // 取景器区域
                ZStack {
                    // 底层：暗色背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.05))
                        .frame(width: 300, height: 400)
                    
                    // 双重影像
                    ZStack {
                        // 影像 1 - 青色偏移 (模拟徕卡的色差)
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 360)
                            .colorMultiply(Color(red: 0.7, green: 0.9, blue: 1.0))
                            .opacity(0.6)
                            .offset(x: -CGFloat(sliderValue) * 30)
                        
                        // 影像 2 - 黄色偏移
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 360)
                            .colorMultiply(Color(red: 1.0, green: 0.95, blue: 0.7))
                            .opacity(0.6)
                            .offset(x: CGFloat(sliderValue) * 30)
                    }
                    .blur(radius: isFocused ? 0 : 1)
                    
                    // 黄斑对焦框
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.mirrorYellow.opacity(isFocused ? 1 : 0.5), lineWidth: 1)
                        .frame(width: 80, height: 80)
                        .background(
                            Color.mirrorYellow.opacity(isFocused ? 0.15 : 0.05)
                        )
                    
                    // 合焦成功指示
                    if showSuccess {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.mirrorYellow)
                            Text("已加入作品集")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.mirrorYellow)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // 对焦滑块
                VStack(spacing: 12) {
                    // 刻度条
                    HStack(spacing: 2) {
                        ForEach(0..<21) { i in
                            Rectangle()
                                .fill(Color.white.opacity(i == 10 ? 0.8 : 0.3))
                                .frame(width: 1, height: i == 10 ? 12 : 6)
                        }
                    }
                    
                    // 滑块
                    Slider(value: $sliderValue, in: -0.5...0.5)
                        .accentColor(.mirrorYellow)
                        .disabled(isFocused)
                        .onChange(of: sliderValue) { _, newValue in
                            checkFocus(value: newValue)
                        }
                    
                    Text(isFocused ? "合焦!" : "左右滑动对齐影像")
                        .font(.system(size: 12))
                        .foregroundColor(isFocused ? .mirrorYellow : .gray)
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private func checkFocus(value: Double) {
        let focused = abs(value) < focusThreshold
        
        if focused && !isFocused {
            // 刚刚合焦
            withAnimation(.easeOut(duration: 0.2)) {
                isFocused = true
            }
            
            // 触觉反馈
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // 延迟显示成功状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showSuccess = true
                }
                
                // 回调
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onFocused()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RangefinderEffect(
        image: UIImage(systemName: "photo")!,
        onFocused: { print("Focused!") }
    )
}
