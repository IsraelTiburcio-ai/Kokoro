import SwiftUI
import SwiftData
import Contacts
import ContactsUI

// MARK: - Modelo

@Model
final class EmergencySupportContact {
    @Attribute(.unique) var id: UUID
    var name: String
    var phoneNumber: String
    var relationship: String
    var isPrimary: Bool
    var source: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String,
        relationship: String = "",
        isPrimary: Bool = false,
        source: String = "manual",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationship = relationship
        self.isPrimary = isPrimary
        self.source = source
        self.createdAt = createdAt
    }
}

// MARK: - Vista principal

struct EmergencyContactsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \EmergencySupportContact.createdAt, order: .forward)
    private var storedContacts: [EmergencySupportContact]

    @State private var selectedSection: EmergencySection = .nearby
    @State private var showContactPicker = false
    @State private var showManualSheet = false
    @State private var showNumberPicker = false
    @State private var showPermissionAlert = false
    @State private var duplicateAlertMessage = ""

    @State private var importedName = ""
    @State private var importedNumbers: [String] = []

    @State private var manualName = ""
    @State private var manualRelationship = ""
    @State private var manualPhone = ""

    @State private var feedbackToken = 0

    var body: some View {
        NavigationStack {
            ZStack {
                supportBackground

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 22) {
                        heroSection
                        segmentedControl

                        if selectedSection == .nearby {
                            nearbyContent
                        } else {
                            locatelContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showContactPicker) {
                EmergencyContactPicker { name, numbers in
                    importedName = name
                    importedNumbers = numbers

                    if numbers.count == 1, let number = numbers.first {
                        addImportedContact(name: name, number: number)
                    } else if !numbers.isEmpty {
                        showNumberPicker = true
                    }
                }
            }
            .sheet(isPresented: $showManualSheet) {
                manualAddSheet
            }
            .confirmationDialog(
                "Elige el número correcto",
                isPresented: $showNumberPicker,
                titleVisibility: .visible
            ) {
                ForEach(importedNumbers, id: \.self) { number in
                    Button(number) {
                        addImportedContact(name: importedName, number: number)
                    }
                }

                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Selecciona qué número quieres guardar como contacto de apoyo.")
            }
            .alert("Permiso de contactos", isPresented: $showPermissionAlert) {
                Button("Abrir ajustes") {
                    openSettings()
                }
                Button("Agregar manualmente") {
                    showManualSheet = true
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("No pudimos acceder a tus contactos. Puedes permitir acceso en Ajustes o agregar a alguien manualmente.")
            }
            .alert("Contacto duplicado", isPresented: duplicateAlertBinding) {
                Button("OK", role: .cancel) {
                    duplicateAlertMessage = ""
                }
            } message: {
                Text(duplicateAlertMessage)
            }
            .sensoryFeedback(.success, trigger: feedbackToken)
        }
    }
}

// MARK: - Secciones

private extension EmergencyContactsView {
    var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.32), lineWidth: 1)
                        }
                        .frame(width: 72, height: 72)

                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Tu red de apoyo")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Si hoy necesitas hablar con alguien, aquí tienes ayuda rápida a un toque.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                quickActionButton(
                    title: "Desde contactos",
                    systemImage: "person.crop.circle.badge.plus"
                ) {
                    handleAddFromContacts()
                }

                quickActionButton(
                    title: "Agregar manual",
                    systemImage: "square.and.pencil"
                ) {
                    showManualSheet = true
                }
            }
        }
    }

    var segmentedControl: some View {
        HStack(spacing: 10) {
            ForEach(EmergencySection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: section.systemImage)
                        Text(section.title)
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(selectedSection == section ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Group {
                            if selectedSection == section {
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                LinearGradient(
                                    colors: [.white.opacity(0.62), .white.opacity(0.48)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                    )
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
    }

    var nearbyContent: some View {
        VStack(spacing: 18) {
            if let primary = primaryContact {
                primaryContactCard(primary)
            } else {
                emptyPrimaryCard
            }

            if contactsAuthorizationStatus == .denied || contactsAuthorizationStatus == .restricted {
                permissionHelpCard
            }

            if secondaryContacts.isEmpty, primaryContact == nil {
                emptyContactsCard
            } else {
                supportListSection
            }
        }
    }

    var locatelContent: some View {
        VStack(spacing: 18) {
            locatelHeroCard
            locatelInfoCard
        }
    }
}

// MARK: - Nearby blocks

private extension EmergencyContactsView {
    func primaryContactCard(_ contact: EmergencySupportContact) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.22), Color.blue.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)

                    Image(systemName: "person.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(contact.name)
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Principal")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule(style: .continuous))
                    }

                    Text(contact.relationship.trimmedNonEmpty ?? "Persona de confianza")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text(contact.phoneNumber)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text("No tienes que pasar por esto solo. Este es tu acceso más rápido a alguien de confianza.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                primaryActionButton(
                    title: "Llamar",
                    systemImage: "phone.fill",
                    colors: [Color.green, Color.green.opacity(0.75)]
                ) {
                    callNumber(contact.phoneNumber)
                }

                primaryActionButton(
                    title: "Mensaje",
                    systemImage: "message.fill",
                    colors: [Color.purple, Color.blue]
                ) {
                    sendQuickMessage(to: contact.phoneNumber, name: contact.name)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    var emptyPrimaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tu contacto principal aún no está definido.")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Agrega a alguien de confianza para tener un acceso inmediato cuando necesites hablar con alguien.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                primaryActionButton(
                    title: "Agregar desde contactos",
                    systemImage: "person.crop.circle.badge.plus",
                    colors: [Color.purple, Color.blue]
                ) {
                    handleAddFromContacts()
                }

                secondaryPillButton(title: "Agregar manual") {
                    showManualSheet = true
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
    }

    var permissionHelpCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Acceso a contactos desactivado")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Puedes seguir usando esta sección agregando personas manualmente, o activar permisos en Ajustes para elegirlas desde tu agenda.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                secondaryPillButton(title: "Abrir ajustes") {
                    openSettings()
                }

                secondaryPillButton(title: "Agregar manual") {
                    showManualSheet = true
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.60))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    var emptyContactsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.purple.opacity(0.75))

            Text("Aún no has agregado personas cercanas")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Empieza con una o dos personas con las que te sientas seguro. Podrás llamarlas o enviarles un mensaje rápido.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    var supportListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personas cercanas")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                ForEach(orderedContacts) { contact in
                    supportRow(contact)
                }
            }
        }
    }

    func supportRow(_ contact: EmergencySupportContact) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(contact.isPrimary ? Color.purple.opacity(0.20) : Color.blue.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: contact.isPrimary ? "star.fill" : "person.fill")
                    .foregroundStyle(contact.isPrimary ? .purple : .blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(contact.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    if contact.isPrimary {
                        Text("Principal")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.purple.opacity(0.10))
                            .clipShape(Capsule(style: .continuous))
                    }
                }

                Text(contact.relationship.trimmedNonEmpty ?? "Persona cercana")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(contact.phoneNumber)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                miniCircleButton(systemImage: "message.fill", color: .purple) {
                    sendQuickMessage(to: contact.phoneNumber, name: contact.name)
                }

                miniCircleButton(systemImage: "phone.fill", color: .green) {
                    callNumber(contact.phoneNumber)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !contact.isPrimary {
                Button {
                    setPrimary(contact)
                } label: {
                    Label("Principal", systemImage: "star.fill")
                }
                .tint(.purple)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                delete(contact)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                setPrimary(contact)
            } label: {
                Label(contact.isPrimary ? "Ya es principal" : "Marcar como principal", systemImage: "star.fill")
            }

            Button {
                sendQuickMessage(to: contact.phoneNumber, name: contact.name)
            } label: {
                Label("Enviar mensaje", systemImage: "message.fill")
            }

            Button(role: .destructive) {
                delete(contact)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

// MARK: - Locatel blocks

private extension EmergencyContactsView {
    var locatelHeroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.16))
                        .frame(width: 62, height: 62)

                    Image(systemName: "phone.badge.waveform.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Locatel CDMX")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Orientación y apoyo telefónico")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text("55 5658 1111")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()
            }

            Text("Úsalo cuando necesites orientación, contención o saber a dónde acudir. Si hay una emergencia inmediata o riesgo inminente, llama al 911.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            primaryActionButton(
                title: "Llamar a Locatel",
                systemImage: "phone.fill",
                colors: [Color.blue, Color.purple]
            ) {
                callNumber("5556581111")
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
    }

    var locatelInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("¿Cuándo usar cada opción?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            infoRow(
                title: "Persona cercana",
                subtitle: "Cuando necesitas compañía, hablar con alguien o sentirte acompañado de inmediato.",
                tint: .purple
            )

            infoRow(
                title: "Locatel",
                subtitle: "Cuando buscas orientación, apoyo institucional o no sabes a quién llamar.",
                tint: .blue
            )

            infoRow(
                title: "911",
                subtitle: "Cuando hay una emergencia inmediata, peligro físico o riesgo inminente.",
                tint: .red
            )
        }
        .padding(20)
        .background(.white.opacity(0.64))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    func infoRow(title: String, subtitle: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 34, height: 34)
                .overlay {
                    Circle()
                        .fill(tint)
                        .frame(width: 10, height: 10)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

// MARK: - Sheets

private extension EmergencyContactsView {
    var manualAddSheet: some View {
        NavigationStack {
            Form {
                Section("Nueva persona cercana") {
                    TextField("Nombre", text: $manualName)
                    TextField("Relación (ej. Mamá, Amiga, Pareja)", text: $manualRelationship)
                    TextField("Teléfono", text: $manualPhone)
                        .keyboardType(.phonePad)
                }

                Section {
                    Text("También puedes usar esta opción si no quieres dar permiso a Contactos o si prefieres escribir el número manualmente.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Agregar contacto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        resetManualForm()
                        showManualSheet = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveManualContact()
                    }
                    .disabled(manualName.trimmedNonEmpty == nil || cleanedPhoneNumber(manualPhone).count < 8)
                }
            }
        }
    }
}

// MARK: - UI Helpers

private extension EmergencyContactsView {
    var supportBackground: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.14),
                Color.blue.opacity(0.10),
                Color.white,
                Color.mint.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color.purple.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 42)
                .offset(x: -80, y: -40)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.blue.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 42)
                .offset(x: 90, y: 90)
        }
    }

    func quickActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(0.56))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func primaryActionButton(
        title: String,
        systemImage: String,
        colors: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func secondaryPillButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white.opacity(0.58))
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func miniCircleButton(systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lógica

private extension EmergencyContactsView {
    var contactsAuthorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    var orderedContacts: [EmergencySupportContact] {
        storedContacts.sorted {
            if $0.isPrimary != $1.isPrimary {
                return $0.isPrimary && !$1.isPrimary
            }
            return $0.createdAt < $1.createdAt
        }
    }

    var primaryContact: EmergencySupportContact? {
        orderedContacts.first(where: { $0.isPrimary })
    }

    var secondaryContacts: [EmergencySupportContact] {
        orderedContacts.filter { !$0.isPrimary }
    }

    var duplicateAlertBinding: Binding<Bool> {
        Binding(
            get: { !duplicateAlertMessage.isEmpty },
            set: { newValue in
                if !newValue { duplicateAlertMessage = "" }
            }
        )
    }

    func handleAddFromContacts() {
        switch contactsAuthorizationStatus {
        case .authorized:
            showContactPicker = true

        case .notDetermined:
            CNContactStore().requestAccess(for: .contacts) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        showContactPicker = true
                    } else {
                        showPermissionAlert = true
                    }
                }
            }

        case .denied, .restricted:
            showPermissionAlert = true

        @unknown default:
            showPermissionAlert = true
        }
    }

    func addImportedContact(name: String, number: String) {
        let cleaned = cleanedPhoneNumber(number)

        guard !cleaned.isEmpty else { return }

        if storedContacts.contains(where: { cleanedPhoneNumber($0.phoneNumber) == cleaned }) {
            duplicateAlertMessage = "Ese número ya está guardado como contacto de apoyo."
            return
        }

        let contact = EmergencySupportContact(
            name: name,
            phoneNumber: number,
            relationship: "",
            isPrimary: storedContacts.isEmpty,
            source: "system"
        )

        if storedContacts.isEmpty {
            contact.isPrimary = true
        }

        modelContext.insert(contact)
        guard persistChanges(action: "addImportedContact") else { return }
        feedbackToken += 1
    }

    func saveManualContact() {
        let cleaned = cleanedPhoneNumber(manualPhone)

        guard let name = manualName.trimmedNonEmpty, cleaned.count >= 8 else { return }

        if storedContacts.contains(where: { cleanedPhoneNumber($0.phoneNumber) == cleaned }) {
            duplicateAlertMessage = "Ese número ya está guardado como contacto de apoyo."
            return
        }

        let contact = EmergencySupportContact(
            name: name,
            phoneNumber: manualPhone,
            relationship: manualRelationship,
            isPrimary: storedContacts.isEmpty,
            source: "manual"
        )

        modelContext.insert(contact)
        guard persistChanges(action: "saveManualContact") else { return }
        feedbackToken += 1

        resetManualForm()
        showManualSheet = false
    }

    func resetManualForm() {
        manualName = ""
        manualRelationship = ""
        manualPhone = ""
    }

    func setPrimary(_ selected: EmergencySupportContact) {
        for contact in storedContacts {
            contact.isPrimary = (contact.id == selected.id)
        }
        _ = persistChanges(action: "setPrimary")
        feedbackToken += 1
    }

    func delete(_ contact: EmergencySupportContact) {
        let wasPrimary = contact.isPrimary
        modelContext.delete(contact)
        _ = persistChanges(action: "deleteContact")

        if wasPrimary, let next = storedContacts.filter({ $0.id != contact.id }).sorted(by: { $0.createdAt < $1.createdAt }).first {
            setPrimary(next)
        }
    }

    @discardableResult
    func persistChanges(action: String) -> Bool {
        do {
            try modelContext.save()
            print("✅ [EmergencyContacts] Save OK (\(action))")
            return true
        } catch {
            modelContext.rollback()
            print("❌ [EmergencyContacts] Save FAILED (\(action)): \(error.localizedDescription)")
            return false
        }
    }

    func callNumber(_ number: String) {
        let cleaned = cleanedPhoneNumber(number)
        guard let url = URL(string: "tel://\(cleaned)") else { return }
        UIApplication.shared.open(url)
    }

    func sendQuickMessage(to number: String, name: String) {
        let cleaned = cleanedPhoneNumber(number)
        let message = "Hola \(name), no me siento muy bien en este momento. ¿Podrías hablar conmigo?"
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "sms:\(cleaned)&body=\(encodedMessage)") else { return }
        UIApplication.shared.open(url)
    }

    func cleanedPhoneNumber(_ value: String) -> String {
        value.filter { "0123456789+".contains($0) }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Picker de Contactos

private struct EmergencyContactPicker: UIViewControllerRepresentable {
    let onSelect: (String, [String]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (String, [String]) -> Void

        init(onSelect: @escaping (String, [String]) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Sin nombre"
            let numbers = contact.phoneNumbers.map { $0.value.stringValue }.filter { !$0.isEmpty }
            onSelect(name, numbers)
        }
    }
}

// MARK: - Types

private enum EmergencySection: CaseIterable {
    case nearby
    case locatel

    var title: String {
        switch self {
        case .nearby: return "Personas cercanas"
        case .locatel: return "Locatel"
        }
    }

    var systemImage: String {
        switch self {
        case .nearby: return "person.2.fill"
        case .locatel: return "phone.fill"
        }
    }
}

// MARK: - Helpers

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EmergencyContactsView()
            .modelContainer(for: EmergencySupportContact.self, inMemory: true)
    }
}
