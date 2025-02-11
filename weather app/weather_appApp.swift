




import SwiftUI
import SwiftData
import MapKit
import UIKit



@main
struct WeatherApp: App {
    
    var sharedModelContainer: ModelContainer = {
        
        let schema = Schema([FavoriteLocation.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
       
        WindowGroup {
            WeatherView(viewModel: WeatherViewModel())
                .environment(\.modelContext, sharedModelContainer.mainContext)
        }
    }
}
