import SwiftUI
import MEGASwiftUI

struct PhotoCellImage: View {
    let container: any ImageContaining
    var aspectRatio: CGFloat?
    var bgColor = Color.clear
    
    var body: some View {
        if container.isPlaceholder {
            bgColor
                .aspectRatio(contentMode: .fill)
                .overlay(
                    container.image
                )
        } else {
            thumbnail()
        }
    }
    
    private func thumbnail() -> some View {
        container.image
            .resizable()
            .aspectRatio(aspectRatio, contentMode: .fill)
    }
}
