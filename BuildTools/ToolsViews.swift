import SwiftUI

// MARK: - Tools List View
struct ToolsListView: View {
    @EnvironmentObject var toolsVM: ToolsViewModel
    @EnvironmentObject var workersVM: WorkersViewModel
    @State private var showAddTool = false
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tools")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(DS.textPrimary)
                            Text("\(toolsVM.tools.count) total")
                                .font(.system(size: 13))
                                .foregroundColor(DS.textMuted)
                        }
                        Spacer()
                        Button(action: { showAddTool = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(DS.bg0)
                                .frame(width: 36, height: 36)
                                .background(DS.yellow)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DS.textMuted)
                            .font(.system(size: 14))
                        TextField("Search tools...", text: $toolsVM.searchText)
                            .foregroundColor(DS.textPrimary)
                            .font(.system(size: 15))
                    }
                    .padding(12)
                    .background(DS.card)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.divider, lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: toolsVM.selectedStatus == nil) {
                                toolsVM.selectedStatus = nil
                            }
                            ForEach(ToolStatus.allCases, id: \.self) { status in
                                FilterChip(label: status.rawValue,
                                           isSelected: toolsVM.selectedStatus == status,
                                           color: status.color) {
                                    toolsVM.selectedStatus = (toolsVM.selectedStatus == status) ? nil : status
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)

                    // List
                    if toolsVM.filteredTools.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 48))
                                .foregroundColor(DS.textMuted)
                            Text("No tools found")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(DS.textMuted)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 8) {
                                ForEach(toolsVM.filteredTools) { tool in
                                    NavigationLink(destination: ToolDetailView(tool: tool)) {
                                        ToolRowCard(tool: tool)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTool) {
                AddToolView()
            }
        }
    }
}

struct BuildToolsConsentView: View {
    let viewModel: BuildToolsViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("tools")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.acceptConsent()
            } label: {
                Image("tools_b")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                viewModel.skipConsent()
            } label: {
                Text("Skip")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = DS.yellow
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? DS.bg0 : DS.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : DS.card)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color : DS.divider, lineWidth: 1)
                )
        }
        .animation(DS.spring, value: isSelected)
    }
}

// MARK: - Tool Row Card
struct ToolRowCard: View {
    let tool: Tool
    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(DS.yellow.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: tool.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(DS.yellow)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.textPrimary)
                HStack(spacing: 8) {
                    Image(systemName: tool.location.icon)
                        .font(.system(size: 11))
                        .foregroundColor(DS.textMuted)
                    Text(tool.location.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(DS.textMuted)
                    if let assignedTo = tool.assignedTo, !assignedTo.isEmpty {
                        Text("· \(assignedTo)")
                            .font(.system(size: 12))
                            .foregroundColor(DS.textMuted)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(status: tool.status)
                Text(tool.category.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(DS.textMuted)
            }
        }
        .padding(14)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(DS.divider, lineWidth: 1)
        )
    }
}

// MARK: - Tool Detail View
struct ToolDetailView: View {
    @EnvironmentObject var toolsVM: ToolsViewModel
    @EnvironmentObject var workersVM: WorkersViewModel
    @Environment(\.dismiss) var dismiss
    let tool: Tool
    @State private var editedTool: Tool
    @State private var showEdit = false
    @State private var showDelete = false
    @State private var showAssign = false

    init(tool: Tool) {
        self.tool = tool
        _editedTool = State(initialValue: tool)
    }

    var currentTool: Tool {
        toolsVM.tools.first(where: { $0.id == tool.id }) ?? tool
    }

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero
                    ZStack(alignment: .bottom) {
                        LinearGradient(
                            colors: [DS.yellow.opacity(0.15), DS.bg0],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 200)

                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(DS.yellow.opacity(0.15))
                                    .frame(width: 90, height: 90)
                                Image(systemName: currentTool.category.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(DS.yellow)
                            }
                            StatusBadge(status: currentTool.status)
                        }
                        .padding(.bottom, 20)
                    }

                    VStack(spacing: 20) {
                        // Name
                        Text(currentTool.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(DS.textPrimary)
                            .multilineTextAlignment(.center)

                        // Info cards
                        VStack(spacing: 1) {
                            DetailRow(icon: "tag.fill", label: "Category",
                                      value: currentTool.category.rawValue)
                            DetailRow(icon: currentTool.location.icon, label: "Location",
                                      value: currentTool.location.rawValue)
                            DetailRow(icon: "number", label: "Serial Number",
                                      value: currentTool.serialNumber.isEmpty ? "–" : currentTool.serialNumber)
                            if let assignedTo = currentTool.assignedTo, !assignedTo.isEmpty {
                                DetailRow(icon: "person.fill", label: "Assigned To", value: assignedTo)
                            }
                            if !currentTool.notes.isEmpty {
                                DetailRow(icon: "note.text", label: "Notes", value: currentTool.notes)
                            }
                        }
                        .background(DS.card)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))

                        // Status change
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Change Status")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(ToolStatus.allCases, id: \.self) { status in
                                    Button(action: { changeStatus(to: status) }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: status.icon)
                                                .font(.system(size: 13))
                                            Text(status.rawValue)
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundColor(currentTool.status == status ? DS.bg0 : status.color)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(currentTool.status == status ? status.color : status.color.opacity(0.12))
                                        )
                                    }
                                    .animation(DS.spring, value: currentTool.status)
                                }
                            }
                        }

                        // Assign
                        Button(action: { showAssign = true }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Assign to Worker")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        // Edit & Delete
                        HStack(spacing: 12) {
                            Button(action: {
                                editedTool = currentTool
                                showEdit = true
                            }) {
                                HStack { Image(systemName: "pencil"); Text("Edit") }
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button(action: { showDelete = true }) {
                                HStack { Image(systemName: "trash"); Text("Delete") }
                                    .foregroundColor(Color(hex: "#EF4444"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "#EF4444").opacity(0.12))
                                    .cornerRadius(14)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showEdit) {
            AddToolView(editingTool: editedTool)
        }
        .sheet(isPresented: $showAssign) {
            AssignToolView(tool: currentTool)
        }
        .alert("Delete Tool?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                toolsVM.delete(currentTool)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(currentTool.name).")
        }
    }

    private func changeStatus(to status: ToolStatus) {
        var updated = currentTool
        updated.status = status
        toolsVM.update(updated)
        ActivityLog.shared.log("Status changed to \(status.rawValue): \(currentTool.name)",
                                toolName: currentTool.name, type: .updated)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(DS.textMuted)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(DS.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DS.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(14)
        Divider().background(DS.divider).padding(.leading, 48)
    }
}

// MARK: - Add / Edit Tool View
struct AddToolView: View {
    @EnvironmentObject var toolsVM: ToolsViewModel
    @Environment(\.dismiss) var dismiss
    var editingTool: Tool? = nil

    @State private var name = ""
    @State private var category: ToolCategory = .hand
    @State private var status: ToolStatus = .available
    @State private var location: ToolLocation = .home
    @State private var serialNumber = ""
    @State private var notes = ""
    @State private var nameError = false
    @State private var showSavedBanner = false

    var isEditing: Bool { editingTool != nil }

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DS.textMuted)
                            .padding(10)
                            .background(DS.card)
                            .cornerRadius(10)
                    }
                    Spacer()
                    Text(isEditing ? "Edit Tool" : "Add Tool")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(DS.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Tool Name
                        FormField(label: "Tool Name", isError: nameError) {
                            TextField("e.g. DeWalt Drill", text: $name)
                                .foregroundColor(DS.textPrimary)
                                .font(.system(size: 15))
                        }
                        if nameError {
                            Text("Tool name is required")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .padding(.top, -12)
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Category")
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(ToolCategory.allCases, id: \.self) { cat in
                                    Button(action: { category = cat }) {
                                        VStack(spacing: 6) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(category == cat ? DS.bg0 : DS.yellow)
                                            Text(cat.rawValue)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(category == cat ? DS.bg0 : DS.textSecondary)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(category == cat ? DS.yellow : DS.card)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(category == cat ? DS.yellow : DS.divider, lineWidth: 1)
                                                )
                                        )
                                    }
                                    .animation(DS.spring, value: category)
                                }
                            }
                        }

                        // Status
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Status")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(ToolStatus.allCases, id: \.self) { s in
                                    Button(action: { status = s }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: s.icon).font(.system(size: 12))
                                            Text(s.rawValue).font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundColor(status == s ? DS.bg0 : s.color)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(status == s ? s.color : s.color.opacity(0.12))
                                        )
                                    }
                                    .animation(DS.spring, value: status)
                                }
                            }
                        }

                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Location")
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(ToolLocation.allCases, id: \.self) { loc in
                                    Button(action: { location = loc }) {
                                        VStack(spacing: 6) {
                                            Image(systemName: loc.icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(location == loc ? DS.bg0 : DS.blue)
                                            Text(loc.rawValue)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(location == loc ? DS.bg0 : DS.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(location == loc ? DS.blue : DS.card)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(location == loc ? DS.blue : DS.divider, lineWidth: 1)
                                                )
                                        )
                                    }
                                    .animation(DS.spring, value: location)
                                }
                            }
                        }

                        // Serial Number
                        FormField(label: "Serial Number (optional)") {
                            TextField("e.g. DW-001", text: $serialNumber)
                                .foregroundColor(DS.textPrimary)
                                .font(.system(size: 15))
                        }

                        // Notes
                        FormField(label: "Notes (optional)") {
                            TextField("Any additional info...", text: $notes)
                                .foregroundColor(DS.textPrimary)
                                .font(.system(size: 15))
                        }

                        // Save Button
                        Button(action: save) {
                            Text(isEditing ? "Save Changes" : "Add Tool")
                        }
                        .buttonStyle(YellowButtonStyle())
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }

            // Saved Banner
            if showSavedBanner {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "#22C55E"))
                        Text(isEditing ? "Changes saved!" : "Tool added!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DS.textPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(DS.card)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 8)
                    .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if let t = editingTool {
                name = t.name
                category = t.category
                status = t.status
                location = t.location
                serialNumber = t.serialNumber
                notes = t.notes
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { nameError = true }
            return
        }
        nameError = false
        if isEditing, var updated = editingTool {
            updated.name = name
            updated.category = category
            updated.status = status
            updated.location = location
            updated.serialNumber = serialNumber
            updated.notes = notes
            toolsVM.update(updated)
        } else {
            let tool = Tool(name: name, category: category, status: status,
                            location: location, notes: notes, serialNumber: serialNumber)
            toolsVM.add(tool)
        }
        withAnimation { showSavedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }
}

// MARK: - Form Field
struct FormField<Content: View>: View {
    let label: String
    var isError: Bool = false
    let content: Content
    init(label: String, isError: Bool = false, @ViewBuilder content: () -> Content) {
        self.label = label
        self.isError = isError
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: label)
            content
                .padding(14)
                .background(DS.card)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isError ? Color.red : DS.divider, lineWidth: 1)
                )
        }
    }
}

// MARK: - Assign Tool View
struct AssignToolView: View {
    @EnvironmentObject var toolsVM: ToolsViewModel
    @EnvironmentObject var workersVM: WorkersViewModel
    @Environment(\.dismiss) var dismiss
    let tool: Tool
    @State private var selected: Worker? = nil
    @State private var showSaved = false

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DS.textMuted)
                            .padding(10)
                            .background(DS.card)
                            .cornerRadius(10)
                    }
                    Spacer()
                    Text("Assign Tool")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(DS.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding()

                Text("Assign \"\(tool.name)\" to:")
                    .font(.system(size: 15))
                    .foregroundColor(DS.textSecondary)
                    .padding(.bottom, 16)

                // Unassign option
                Button(action: { selected = nil }) {
                    HStack {
                        Image(systemName: "person.slash.fill")
                            .foregroundColor(DS.textMuted)
                        Text("Unassign")
                            .foregroundColor(DS.textMuted)
                        Spacer()
                        if selected == nil && tool.assignedTo == nil {
                            Image(systemName: "checkmark").foregroundColor(DS.yellow)
                        }
                    }
                    .padding(14)
                    .background(DS.card)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(workersVM.workers) { worker in
                            Button(action: { selected = worker }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle().fill(DS.yellow).frame(width: 40, height: 40)
                                        Text(String(worker.name.prefix(1)))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(DS.bg0)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(worker.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(DS.textPrimary)
                                        Text(worker.role)
                                            .font(.system(size: 12))
                                            .foregroundColor(DS.textMuted)
                                    }
                                    Spacer()
                                    if selected?.id == worker.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(DS.yellow)
                                    }
                                }
                                .padding(14)
                                .background(DS.card)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selected?.id == worker.id ? DS.yellow : DS.divider, lineWidth: 1)
                                )
                            }
                            .animation(DS.spring, value: selected?.id)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Button(action: assign) {
                    Text("Confirm Assignment")
                }
                .buttonStyle(YellowButtonStyle())
                .padding(20)
            }
        }
    }

    private func assign() {
        var updated = tool
        updated.assignedTo = selected?.name
        updated.status = selected != nil ? .inUse : .available
        toolsVM.update(updated)
        if let w = selected {
            ActivityLog.shared.log("Assigned \(tool.name) to \(w.name)", toolName: tool.name, type: .assigned)
        } else {
            ActivityLog.shared.log("Unassigned \(tool.name)", toolName: tool.name, type: .returned)
        }
        dismiss()
    }
}
