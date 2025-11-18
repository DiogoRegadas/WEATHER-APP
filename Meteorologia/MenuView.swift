//
//  MenuView.swift
//  Meteorologia
//
//  Created by Diogo Regadas on 09/01/2024.
//

import SwiftUI

struct MenuView: View {
    let locations: [String]
    let onLocationSelect: (String?) -> Void
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 20) {
                Text("Selecione Uma Região: ")
                    .foregroundColor(.white)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .frame(width: 300, height: 30, alignment: .leading)
                    .font(.system(size: 24))
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                ForEach(locations, id: \.self) { location in
                    Button(action: {
                        onLocationSelect(location)
                    }) {
                        Text(location)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                    }
                }
                
                Divider()
                
                Button(action: {
                    onLocationSelect(nil) // Handle the case where no location is selected
                }) {
                    Text("CANCELAR")
                        .foregroundColor(.red)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                }
            }
            .padding()
            .background(Color(red: 65 / 255.0, green: 189 / 255.0, blue: 232 / 255.0))
            .navigationBarHidden(true)
        }
        .background(Color(red: 65 / 255.0, green: 189 / 255.0, blue: 232 / 255.0))
    }
}
