//
//  visualStyleManager.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-28.
//

import SwiftUI

class VisualStyleManager: ObservableObject {
    @AppStorage("useSolidColorBackground") var useSolidColorBackground: Bool = false
}
