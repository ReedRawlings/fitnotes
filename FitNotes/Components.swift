// MARK: - Components.swift
// Central export file for FitNotes Components

import SwiftUI

// MARK: - BaseCardView
struct BaseCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(Color.secondaryBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

// MARK: - CardListView
struct CardListView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    init(_ items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - CardRowView
 struct CardRowView<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let trailingContent: Trailing?
    
 init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailingContent: @escaping () -> Trailing? = { nil }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = trailingContent()
    }
    
 var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            if let trailing = trailingContent {
                trailing
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - SectionHeaderView
 struct SectionHeaderView: View {
    let title: String
    let actionTitle: String?
    let onAction: (() -> Void)?
    
 init(
        title: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.onAction = onAction
    }
    
 var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentPrimary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - EmptyStateView
 struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let onAction: (() -> Void)?
    
 init(
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
    
 var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.textTertiary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
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
                    .background(
                        LinearGradient(
                            colors: [.accentPrimary, .accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.textInverse)
                    .cornerRadius(16)
                    .shadow(
                        color: .accentPrimary.opacity(0.3),
                        radius: 16,
                        x: 0,
                        y: 4
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
}



// MARK: - PrimaryActionButton
 struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let onTap: () -> Void
    
 init(title: String, icon: String = "plus", onTap: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.onTap = onTap
    }
    
 var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.buttonFont)
            }
            .foregroundColor(.textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.accentPrimary, .accentSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: .accentPrimary.opacity(0.3),
                radius: 16,
                x: 0,
                y: 4
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - SecondaryActionButton
 struct SecondaryActionButton: View {
    let title: String
    let icon: String
    let onTap: () -> Void
    
 init(title: String, icon: String = "pause", onTap: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.onTap = onTap
    }
    
 var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.accentPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.secondaryBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 2)
            )
        }
        .padding(.horizontal, 20)
    }
}
