//
//  ContentView.swift
//  Meteorologia
//
//  Created by Ronald Costa on 08/01/2024.
//

import SwiftUI

struct LocationData: Codable {
    let owner: String
    let country: String
    let data: [Location]
}

struct Location: Codable, Identifiable, Hashable {
    let idRegiao: Int
    let idAreaAviso: String
    let idConcelho: Int
    let globalIdLocal: Int
    let latitude: String
    let idDistrito: Int
    let local: String
    let longitude: String

    var id: Int {
        return globalIdLocal
    }
}

struct WeatherData: Codable {
    let owner: String
    let country: String
    let data: [DailyForecast]
    let globalIdLocal: Int
    let dataUpdate: String
}

struct DailyForecast: Codable {
    let precipitaProb: String
    let tMin: String
    let tMax: String
    let predWindDir: String
    let idWeatherType: Int
    let classWindSpeed: Int
    let longitude: String
    let forecastDate: String
    let latitude: String
}

class WeatherViewModel: ObservableObject {
    @Published var weatherData: WeatherData?
    @Published var locations: [Location]?
    @Published var searchText: String = ""
    @Published var selectedDayIndex: Int = 0 {
            didSet {
                // Notificar a mudança da propriedade
                self.objectWillChange.send()
            }
        }
    @Published var locationSelect : Location?

    func fetchLocations() {
        let locationsURL = "https://api.ipma.pt/open-data/distrits-islands.json"
        guard let url = URL(string: locationsURL) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Erro ao obter dados de localização:", error?.localizedDescription ?? "Erro desconhecido")
                return
            }

            do {
                let decodedData = try JSONDecoder().decode(LocationData.self, from: data)
                DispatchQueue.main.async {
                    self.locations = decodedData.data
                    
                }
            } catch {
                print("Erro ao decodificar dados de localização:", error.localizedDescription)
            }
        }.resume()
    }

    func fetchData(forGlobalIdLocal globalIdLocal: Int, date: String, forLocation location: Location) {
            let weatherURL = "https://api.ipma.pt/open-data/forecast/meteorology/cities/daily/\(location.globalIdLocal).json"
            guard let url = URL(string: weatherURL) else { return }

            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else {
                    print("Erro ao obter dados meteorológicos:", error?.localizedDescription ?? "Erro desconhecido")
                    return
                }

                do {
                    let decodedData = try JSONDecoder().decode(WeatherData.self, from: data)
                    
                    
                    DispatchQueue.main.async {
                        self.weatherData = decodedData
                        self.locationSelect = location
                        
                        print(decodedData)
                    }
                } catch {
                    print("Erro ao decodificar dados meteorológicos:", error.localizedDescription)
                }
            }.resume()
        }
    
    
    func nextDay() {
        guard let weatherData = weatherData, let selectedLocation = locationSelect else { return }
        selectedDayIndex = min(selectedDayIndex + 1, weatherData.data.count - 1)

        print(selectedLocation)
        // Após mudar o dia, solicitar dados para o novo dia selecionado
        fetchData(forGlobalIdLocal: selectedLocation.globalIdLocal, date: weatherData.data[selectedDayIndex].forecastDate, forLocation: selectedLocation)
        
    }

    func previousDay() {
        guard let weatherData = weatherData, let selectedLocation = locationSelect else { return }
        selectedDayIndex = max(selectedDayIndex - 1, 0)
        
        print(selectedLocation)
        // Após mudar o dia, solicitar dados para o novo dia selecionado
        fetchData(forGlobalIdLocal: selectedLocation.globalIdLocal, date: weatherData.data[selectedDayIndex].forecastDate, forLocation: selectedLocation)
            }
    
    
    func getCurrentDate() -> String {
        let currentDate = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return dateFormatter.string(from: currentDate)
    }
    
    
}


struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var isMenuOpen = false
    
    func getTimeOfDay() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Definição da hora de inicio e termino do periodo da manhã
        let startHour = 6
        let endHour = 19
        
        let hour = calendar.component(.hour, from: now)
        
        // Verifica se a hora atual é de dia ou de noite
        if startHour < hour && hour < endHour {
            return "d"
        } else {
            return "n"
        }
    }
    
    func getBackgroundColor() -> Color {
        let timeOfDay = getTimeOfDay()
        let weatherType = viewModel.weatherData?.data[viewModel.selectedDayIndex].idWeatherType ?? 0
        
        if timeOfDay == "d" {
            // Cores de fundo dinamicas
            switch weatherType {
            case 1, 2, 3, 25, 27:
                return Color(red: 65 / 255.0, green: 189 / 255.0, blue: 232 / 255.0) // Dias de sol
            case 4, 5, 6, 7, 8, 16, 20, 24, 26, 28, 30:
                return Color(red: 54 / 255.0, green: 155 / 255.0, blue: 187 / 255.0) // Dias nublados
            case 9, 10, 11, 12, 13, 14, 15, 18, 19, 21, 22, 23, 29:
                return Color(red: 84 / 255.0, green: 121 / 255.0, blue: 131 / 255.0) // Dias de mau tempo
            default:
                return Color(red: 65 / 255.0, green: 189 / 255.0, blue: 232 / 255.0) //Default são dias de sol
            }
        } else {
            return Color(red: 21 / 255.0, green: 56 / 255.0, blue: 67 / 255.0)
 // Horario noturno
        }
    }

    
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Button(action: {
                            isMenuOpen.toggle()
                        }) {
                            Image("menu")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 35, height: 35)
                                .padding()
                        }
                        Spacer()
                        
                        Button(action: {
                            if viewModel.selectedDayIndex > 0 {
                                viewModel.previousDay()
                            }
                        }) {
                            Image("back")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .padding()
                        }
                        
                        Button(action: {
                            if viewModel.selectedDayIndex < 5 {
                                viewModel.nextDay()
                            }
                        }) {
                            Image("forward")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .padding()
                        }
                    }
                    .padding(EdgeInsets(top: -20, leading: 20, bottom: 0, trailing: 10))
                    .foregroundColor(.white)
                    .background(getBackgroundColor())
                }
            
                
                ScrollView {
                    VStack {
                        
                        // Mostre a lista inicial somente se a localização não tiver um valor atribuido
                        if viewModel.locationSelect == nil {
                            // Botões para cada localização
                            Text("Selecione Uma Região: ")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                                .fontWeight(.bold)
                                .padding(.vertical, 10)
                            ForEach(viewModel.locations ?? [], id: \.self) { location in
                                Button(action: {
                                    viewModel.fetchData(forGlobalIdLocal: location.globalIdLocal, date: viewModel.getCurrentDate(), forLocation: location)
                                }) {
                                    Text(location.local)
                                        .foregroundColor(.white)
                                        .font(.system(size: 20))
                                        .fontWeight(.semibold)
                                        .padding(.vertical, -1)
                                }
                            }
                        }
                        
                        
                        if let weatherData = viewModel.weatherData {
                            // Exiba os dados meteorológicos conforme necessário
                            Text("Data: \(weatherData.data[viewModel.selectedDayIndex].forecastDate)")
                                .foregroundColor(.white)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .font(.system(size: 24))
                                .frame(width: 300, height: 20, alignment: .center)
                                .padding(EdgeInsets(top: 40, leading: 0, bottom: 40, trailing: 0))
                            Text("Localização: \(viewModel.locationSelect?.local ?? "Nenhuma Localidade Escolhida")")
                                .foregroundColor(.white)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .font(.system(size: 22))
                                .frame(width: 300, height: 20, alignment: .center)
                                .padding(.vertical, 4)
                            Image("w_ic_\(getTimeOfDay())_\(weatherData.data[viewModel.selectedDayIndex].idWeatherType)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150, height: 150)
                                .padding()
                            HStack {
                                Text("Min: \(weatherData.data[viewModel.selectedDayIndex].tMin)˚")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .font(.system(size: 26))
                                    .frame(width: 150, height: 20, alignment: .center)
                                Text("Max: \(weatherData.data[viewModel.selectedDayIndex].tMax)˚")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .font(.system(size: 26))
                                    .frame(width: 150, height: 20, alignment: .center)
                            }
                            .padding(.vertical, 4)
                            Text("Precipitação: \(weatherData.data[viewModel.selectedDayIndex].precipitaProb) %")
                                .foregroundColor(.white)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .font(.system(size: 22))
                                .frame(width: 300, height: 20, alignment: .center)
                                .padding(.vertical, 20)
                            Text("Vento:")
                                .foregroundColor(.white)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .font(.system(size: 24))
                                .frame(width: 280, height: 20, alignment: .leading)
                                .padding(.vertical, 2)
                            Text("Força: \(weatherData.data[viewModel.selectedDayIndex].classWindSpeed)")
                                .foregroundColor(.white)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .font(.system(size: 22))
                                .frame(width: 300, height: 20, alignment: .center)
                                .padding(.vertical, 4)
                            Text("Direção: \(weatherData.data[viewModel.selectedDayIndex].predWindDir)")
                                .foregroundColor(.white)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .font(.system(size: 22))
                                .frame(width: 300, height: 20, alignment: .center)
                                .padding(.vertical, 4)
                            // ... adicione mais visualizações conforme necessário
                        }
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(getBackgroundColor())
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        viewModel.fetchLocations()
                    }
                    
                    .overlay(
                        NavigationLink(
                            destination: MenuView(locations: viewModel.locations?.map { $0.local } ?? [], onLocationSelect: { selectedLocation in
                                if let locationName = selectedLocation {
                                    if let location = viewModel.locations?.first(where: { $0.local == locationName }) {
                                        viewModel.fetchData(forGlobalIdLocal: location.globalIdLocal, date: viewModel.getCurrentDate(), forLocation: location)
                                    } else {
                                        print("Região não encontrada.")
                                    }
                                } else {
                                    print("Nenhuma localização selecionada.")
                                }
                                isMenuOpen.toggle()
                            }),
                            isActive: $isMenuOpen
                        ) {
                            EmptyView()
                        }
                    )
                }
                .background(getBackgroundColor()) // Set the background color of ScrollView
                .padding(EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 0))
            }
        }
    }
}

struct WeatherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
