////
////  PreviewData.swift
////  futurepath
////
////  Created on 2025-10-15
////
//
//import SwiftUI
//import Combine
//
///// Centralized static sample data for SwiftUI previews.
//enum PreviewData {
//
//    static let theme: AppTheme = {
//        let t = AppTheme()
//        t.isDarkMode = false
//        return t
//    }()
//
//    static let settings = SettingsStore()
//
//    static let moods: [Mood] = Mood.allCases
//
//    static let tasks: [TaskItem] = [
//        TaskItem(
//            title: "Read 10 pages",
//            note: "Evening routine",
//            moodHint: .calm,
//            dueDate: Date(),
//            isDone: false,
//            colorID: "brandGreen",
//            iconName: IconLibrary.study
//        ),
//        TaskItem(
//            title: "Workout session",
//            note: "30 mins strength training",
//            moodHint: .focused,
//            dueDate: Date(),
//            isDone: false,
//            colorID: "brandBlue",
//            iconName: IconLibrary.sport
//        ),
//        TaskItem(
//            title: "Call mom",
//            note: nil,
//            moodHint: .tired,
//            dueDate: Date().adding(days: 1),
//            isDone: true,
//            colorID: "brandCoral",
//            iconName: IconLibrary.social
//        ),
//        TaskItem(
//            title: "Plan weekend trip",
//            note: "Check train schedule",
//            moodHint: .inspired,
//            dueDate: Date().adding(days: 2),
//            isDone: false,
//            colorID: "brandYellow",
//            iconName: IconLibrary.travel
//        )
//    ]
//
//    static let plans: [DayPlan] = [
//        DayPlan(date: Date().adding(days: -1), selectedMood: .focused, tasks: Array(tasks.prefix(2))),
//        DayPlan(date: Date(), selectedMood: .calm, tasks: Array(tasks.prefix(3))),
//        DayPlan(date: Date().adding(days: 1), selectedMood: .inspired, tasks: Array(tasks.suffix(2)))
//    ]
//
//    static let moodRepo: MoodRepository = {
//        let repo = MoodRepository()
//        // keep preview data isolated: wipe and repopulate through public API
//        repo.clearAll()
//        plans.forEach { repo.update($0) } // update()
//        return repo
//    }()
//
//    static let taskRepo: TaskRepository = {
//        let repo = TaskRepository()
//        repo.clearAll()
//        repo.addMany(tasks) //
//        return repo
//    }()
//
//    static let appState: AppState = {
//        let state = AppState()
//        state.selectedTab = .today
//        return state
//    }()
//
//    static let moodEngine = MoodEngine()
//    static let taskEngine = TaskEngine()
//    static let statsEngine = StatsEngine()
//
//    static let moodVM = MoodPickerViewModel(
//        appState: appState,
//        moodRepository: moodRepo,
//        taskRepository: taskRepo,
//        moodEngine: moodEngine,
//        taskEngine: taskEngine,
//        settings: settings
//    )
//
//    static let taskListVM = TaskListViewModel(
//        appState: appState,
//        tasksRepository: taskRepo,
//        taskEngine: taskEngine
//    )
//
//    static let statsVM = StatsViewModel(
//        appState: appState,
//        moodRepository: moodRepo,
//        taskRepository: taskRepo,
//        statsEngine: statsEngine
//    )
//
//    static let settingsVM = SettingsViewModel(
//        settings: settings,
//        theme: theme
//    )
//}
//
//#if DEBUG
//struct PreviewData_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack(spacing: 10) {
//            MoodBadge(mood: .calm)
//            TaskRowView(item: PreviewData.tasks.first!)
//            EmptyStateView(title: "No tasks today", message: "Tap + to add one")
//        }
//        .environmentObject(PreviewData.theme)
//        .environmentObject(PreviewData.settings)
//        .padding()
//        .previewLayout(.sizeThatFits)
//    }
//}
//#endif
