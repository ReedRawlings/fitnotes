// MARK: - Components.swift
// Central export file for FitNotes Components

import SwiftUI

// MARK: - BaseCardView
public struct BaseCardView<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(16)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - CardListView
public struct CardListView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    public init(_ items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - CardRowView
public struct CardRowView<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let trailingContent: Trailing?
    
    public init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailingContent: @escaping () -> Trailing? = { nil }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = trailingContent()
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let trailing = trailingContent {
                trailing
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - SectionHeaderView
public struct SectionHeaderView: View {
    let title: String
    let actionTitle: String?
    let onAction: (() -> Void)?
    
    public init(
        title: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.onAction = onAction
    }
    
    public var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - EmptyStateView
public struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let onAction: (() -> Void)?
    
    public init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.onAction = onAction
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    HStack {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - ProgressIndicatorView
public struct ProgressIndicatorView: View {
    let completed: Int
    let total: Int
    
    public init(completed: Int, total: Int) {
        self.completed = completed
        self.total = total
    }
    
    public var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(completed)/\(total)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("exercises")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - WorkoutHeaderCardView
public struct WorkoutHeaderCardView: View {
    let workoutName: String
    let startTime: Date
    let completed: Int
    let total: Int
    
    public init(
        workoutName: String,
        startTime: Date,
        completed: Int,
        total: Int
    ) {
        self.workoutName = workoutName
        self.startTime = startTime
        self.completed = completed
        self.total = total
    }
    
    public var body: some View {
        BaseCardView {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workoutName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Started \(startTime, style: .time)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    ProgressIndicatorView(completed: completed, total: total)
                }
                
                ProgressView(value: Double(completed), total: Double(total))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
            }
        }
    }
}

// MARK: - PrimaryActionButton
public struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let onTap: () -> Void
    
    public init(title: String, icon: String = "plus", onTap: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.purple)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - SecondaryActionButton
public struct SecondaryActionButton: View {
    let title: String
    let icon: String
    let onTap: () -> Void
    
    public init(title: String, icon: String = "pause", onTap: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray5))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
    }
}
