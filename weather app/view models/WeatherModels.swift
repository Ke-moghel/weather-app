

import SwiftUI

struct WeatherDay: Identifiable {
    let id = UUID()
    let day: String
    let temperature: Int
//    let weatherIcon: String
    let weatherIconURL: String
}


struct WeatherResponse: Codable {
    let name: String 
    let main: Main
    let weather: [Weather]

    var currentTemp: Double { main.temp }
    var minTemp: Double { main.tempMin }
    var maxTemp: Double { main.tempMax }
    var condition: String { weather.first?.description.capitalized ?? "Unknown" }
}

struct Main: Codable {
    let temp: Double
    let tempMin: Double
    let tempMax: Double
    
    enum CodingKeys: String, CodingKey {
        case temp
        case tempMin = "temp_min"
        case tempMax = "temp_max"
    }
}


import Foundation



//struct Weather: Codable {
//    let description: String
//    let icon: String
//}



struct Weather: Codable {
    let description: String
    let icon: String
    
    var iconURL: String {
        return "https://openweathermap.org/img/wn/\(icon)@2x.png"
    }
}


struct ForecastResponse: Codable {
    let list: [ForecastDay]
}

struct ForecastDay: Codable, Identifiable {
    let id = UUID()
    let dt: TimeInterval
    let main: Main
    let weather: [Weather]

    var date: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date(timeIntervalSince1970: dt))
    }

    var temp: Double { main.temp }
    var condition: String { weather.first?.description.capitalized ?? "Unknown" }
    
    var iconURL: String {
        return weather.first?.iconURL ?? ""
    }
}
