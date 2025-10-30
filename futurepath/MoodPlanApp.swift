//
//  MoodPlanApp.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

@main
struct MoodPlanApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var theme = AppTheme()
    @StateObject private var settings = SettingsStore()
    @StateObject private var moodRepository = MoodRepository()
    @StateObject private var taskRepository = TaskRepository()

    
    
    
    
    
    init() {
        
      
        setupAppearance()
    }

    
    
    var body: some Scene {
        WindowGroup {
         
                RootTabView()
                    .environmentObject(appState)
                    .environmentObject(theme)
                    .environmentObject(settings)
                    .environmentObject(moodRepository)
                    .environmentObject(taskRepository)
                    .preferredColorScheme(theme.isDarkMode ? .dark : .light)
                
                    .onAppear {
                                        
                        ReviewNudge.shared.schedule(after: 60)
                                 
                    }
                
           
            
            
        }
        
        
        
    }
    
    

    private func setupAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance()
    }
}
