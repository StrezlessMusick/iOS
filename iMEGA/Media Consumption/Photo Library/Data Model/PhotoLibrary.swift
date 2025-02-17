import Foundation
import SwiftUI
import MEGADomain

struct PhotoLibrary {
    let photoByYearList: [PhotoByYear]
    
    var photosByMonthList: [PhotoByMonth] {
        photoByYearList.flatMap { $0.contentList }
    }
    
    var photosByDayList: [PhotoByDay] {
        photosByMonthList.flatMap { $0.contentList }
    }
    
    var allPhotos: [NodeEntity] {
        photosByDayList.flatMap { $0.contentList }
    }
    
    var isEmpty: Bool {
        photoByYearList.isEmpty
    }
    
    init(photoByYearList: [PhotoByYear] = []) {
        self.photoByYearList = photoByYearList
    }
}

extension PhotoLibrary: Equatable {
    static func == (lhs: PhotoLibrary, rhs: PhotoLibrary) -> Bool {
        lhs.photoByYearList == rhs.photoByYearList
    }
}

extension PhotoLibrary {
    func photoDateSections(forZoomScaleFactor scaleFactor: Int?) -> [PhotoDateSection] {
        guard let factor = scaleFactor else { return [] }
        
        return factor == 1 ? photosDaySections : photoMonthSections
    }
}
