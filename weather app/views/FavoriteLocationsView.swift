
import SwiftUI
import SwiftData

struct FavoriteLocationsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var locations: [FavoriteLocation]

    var body: some View {
        NavigationStack {
            VStack {
                if locations.isEmpty {
                    Text("No saved locations")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(locations, id: \.self) { location in
                            VStack(alignment: .leading) {
                                Text(location.name)
                                    .font(.headline)
                                Text("Temperature: \(location.temperature)°")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Text("Saved on: \(formattedDate(location.dateSaved))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Lat: \(location.latitude), Lon: \(location.longitude)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onDelete(perform: deleteLocation)
                    }
                }
                
                if !locations.isEmpty {
                    Button("Clear All Locations") {
                        clearAllLocations()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Saved Locations")
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func deleteLocation(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(locations[index])
        }
    }
    
    private func clearAllLocations() {
        for location in locations {
            modelContext.delete(location)
        }
    }
}



