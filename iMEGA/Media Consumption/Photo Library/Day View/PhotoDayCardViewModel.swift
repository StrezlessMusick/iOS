import Foundation
import MEGADomain

@available(iOS 14.0, *)
final class PhotoDayCardViewModel: PhotoCardViewModel {
    private let photoByDay: PhotoByDay
    
    let title: String
    
    var badgeTitle: String? {
        return photoByDay.contentList.count > 1 ? "+\(photoByDay.contentList.count - 1)": nil
    }
    
    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        var attr = photoByDay.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).day().attributed)
        let bold = AttributeContainer.font(.title2.bold())
        attr.replaceAttributes(AttributeContainer.dateField(.month), with: bold)
        attr.replaceAttributes(AttributeContainer.dateField(.day), with: bold)
        
        return attr
    }
    
    init(photoByDay: PhotoByDay,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photoByDay = photoByDay
        title = DateFormatter.dateLong().localisedString(from: photoByDay.categoryDate)
        
        super.init(coverPhoto: photoByDay.coverPhoto, thumbnailUseCase: thumbnailUseCase)
    }
}
