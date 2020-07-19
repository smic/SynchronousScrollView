//
//  ContentView.swift
//  Shared
//
//  Created by Stephan Michels on 18.07.20.
//

import SwiftUI

struct ContentView: View {
    @State private var scrollPositionX1: CGFloat = 0
    @State private var scrollPositionX2: CGFloat = 0
    @State private var scrollPositionY: CGFloat = 0
    
    private var scrollPositionBinding1: Binding<CGPoint> {
        return Binding<CGPoint> { () -> CGPoint in
            return CGPoint(x: self.scrollPositionX1, y: self.scrollPositionY)
        } set: { (point) in
            self.scrollPositionX1 = point.x
            self.scrollPositionY = point.y
        }
    }
    
    private var scrollPositionBinding2: Binding<CGPoint> {
        return Binding<CGPoint> { () -> CGPoint in
            return CGPoint(x: self.scrollPositionX2, y: self.scrollPositionY)
        } set: { (point) in
            self.scrollPositionX2 = point.x
            self.scrollPositionY = point.y
        }
    }
    
    var body: some View {
        return HStack(spacing: 0) {
//            ScrollView(.vertical) {
            CustomScrollView(.vertical, scrollPosition: self.scrollPositionBinding1) {
                LazyVStack {
                    ForEach(0..<20) { index in
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(.accentColor)
                            .overlay(
                                Text("\(index + 1)")
                                    .foregroundColor(.white)
                            )
                            .frame(height: 80)
                            .padding()
                    }
                }
            }
            .frame(width: 200)
            
            Divider()
                .edgesIgnoringSafeArea(.all)
            
//            ScrollView([.vertical, .horizontal]) {
            CustomScrollView([.vertical, .horizontal], scrollPosition: self.scrollPositionBinding2) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(400)), count: 4)) {
                    ForEach(0..<(20 * 4)) { index in
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(.red)
                            .overlay(
                                Text("\(index + 1)")
                                    .foregroundColor(.white)
                            )
                            .frame(height: 80)
                            .padding()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
