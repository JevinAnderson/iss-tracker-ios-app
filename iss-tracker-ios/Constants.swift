//
//  Constants.swift
//  iss-tracker-ios
//
//  Created by Jevin Anderson on 5/4/15.
//  Copyright (c) 2015 jevinanderson. All rights reserved.
//

import UIKit

struct Constants {
    struct Urls {
        static let IssLocation = "http://api.open-notify.org/iss-now.json"
        static let PhotosLayer = "http://services2.arcgis.com/gLefH1ihsr75gzHY/arcgis/rest/services/ISSPhotoLocations_20_34/FeatureServer/0"
        static let WorldImageryBasemap = "http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer"
        static let NASAImage = "http://eol.jsc.nasa.gov/SearchPhotos/photo.pl?"
        static let embeddedImage = "http://eol.jsc.nasa.gov/DatabaseImages/ESC/small/"
    }
    struct Identifiers {
        static let ISSPhotoViewController = "ISSPhotoViewController"
    }
}
