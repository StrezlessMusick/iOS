import Foundation
import MEGADomain

@available(iOS 14.0, *)
final class PhotoMonthCardViewModel: PhotoCardViewModel {
    private let photoByMonth: PhotoByMonth
    
    let title: String
    
    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        var attr = photoByMonth.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).attributed)
        let month = AttributeContainer.dateField(.month)
        let bold = AttributeContainer.font(.title2.bold())
        attr.replaceAttributes(month, with: bold)
        
        return attr
    }

    init(photoByMonth: PhotoByMonth,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photoByMonth = photoByMonth
        title = DateFormatter.monthTemplate().localisedString(from: photoByMonth.categoryDate)
        
        super.init(coverPhoto: photoByMonth.coverPhoto, thumbnailUseCase: thumbnailUseCase)
    }
}
