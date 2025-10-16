//
//  RootTabView.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

struct RootTabView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var settings: SettingsStore

    @StateObject private var focusRepo = FocusRepository()


    @EnvironmentObject private var moodRepo: MoodRepository
    @EnvironmentObject private var taskRepo: TaskRepository

    private let haptics = HapticsManager.shared


    private let moodEngine = MoodEngine()
    private let taskEngine = TaskEngine()
    private let statsEngine = StatsEngine()

    var body: some View {
        TabView(selection: $appState.selectedTab) {

            TodayScreen(
                appState: appState,
                moodRepository: moodRepo,
                taskRepository: taskRepo,
                settings: settings,
                moodEngine: moodEngine,
                taskEngine: taskEngine
            )
            .tabItem {
                Label(AppState.AppTab.today.title, systemImage: AppState.AppTab.today.systemIcon)
            }
            .tag(AppState.AppTab.today)

            
            // Focus
            FocusScreen(
                viewModel: FocusViewModel(repository: focusRepo)
            )
            .tabItem { Label("Focus", systemImage: "timer") }
            .tag(AppState.AppTab.focus) // добавь новый кейс в AppTab, если нужно

            // Journal
            JournalScreen(
                viewModel: JournalViewModel(repo: JournalRepository())
            )
            .tabItem { Label("Journal", systemImage: "book.closed") }
            .tag(AppState.AppTab.journal)
            
            
            
            

            StatsScreen(
                viewModel: StatsViewModel(
                    appState: appState,
                    moodRepository: moodRepo,
                    taskRepository: taskRepo,
                    statsEngine: statsEngine
                )
            )
            .tabItem {
                Label(AppState.AppTab.stats.title, systemImage: AppState.AppTab.stats.systemIcon)
            }
            .tag(AppState.AppTab.stats)

            
            
            
            
            

            SettingsScreen(
                viewModel: SettingsViewModel(settings: settings, theme: theme)
            )
            .tabItem {
                Label(AppState.AppTab.settings.title, systemImage: AppState.AppTab.settings.systemIcon)
            }
            .tag(AppState.AppTab.settings)
        }
        .tint(theme.accentColor)
        .background(theme.background.ignoresSafeArea())
        .onChange(of: appState.selectedTab) { _, _ in
            if settings.hapticsEnabled { haptics.selectionChange() }
        }
    }
}
