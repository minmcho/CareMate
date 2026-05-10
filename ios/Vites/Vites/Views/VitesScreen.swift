import SwiftUI

/// Shared screen scaffold: top bar + scrollable content over the surface tint.
/// Every tab uses this so the brand mark, notification bell, padding and
/// background gradient stay consistent.
struct VitesScreen<Content: View>: View {
    var brandTitle: String = "Vites"
    var hasNotification: Bool = true
    var content: Content

    init(brandTitle: String = "Vites",
         hasNotification: Bool = true,
         @ViewBuilder content: () -> Content) {
        self.brandTitle = brandTitle
        self.hasNotification = hasNotification
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [VitesColor.surfaceContainerLow, VitesColor.surface],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VitesTopBar(title: brandTitle, hasNotification: hasNotification)
                ScrollView(showsIndicators: false) {
                    content
                }
            }
        }
    }
}
