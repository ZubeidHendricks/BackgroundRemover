import SwiftUI
import PhotosUI
import AppFactoryKit

// Background Remover — lift the subject from any photo on-device (iOS 17 subject
// masking). Choose a transparent or colored background; Pro unlocks more
// backgrounds and saving.
struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory
    private let service = BackgroundRemoverService()

    @State private var pickerItem: PhotosPickerItem?
    @State private var inputImage: UIImage?
    @State private var outputImage: UIImage?
    @State private var option: BGOption = .all[0]
    @State private var isProcessing = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    preview
                    optionRow
                    actions
                    if let errorText { Text(errorText).font(.footnote).foregroundStyle(.red) }
                }
                .padding(20)
            }
            .navigationTitle("Background Remover")
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
    }

    private var preview: some View {
        ZStack {
            CheckerboardBackground().clipShape(RoundedRectangle(cornerRadius: 18))
            if let shown = outputImage ?? inputImage {
                Image(uiImage: shown).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "person.and.background.dotted").font(.system(size: 52)).foregroundStyle(.teal)
                    Text("Pick a photo").foregroundStyle(.secondary)
                }
            }
            if isProcessing { ProgressView().controlSize(.large) }
        }
        .frame(height: 340)
    }

    private var optionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BGOption.all) { o in
                    Button { select(o) } label: {
                        VStack(spacing: 6) {
                            Group {
                                if let c = o.color { Color(c) } else { CheckerboardBackground() }
                            }
                            .frame(width: 54, height: 54).clipShape(Circle())
                            .overlay(Circle().strokeBorder(option == o ? .teal : .secondary.opacity(0.3), lineWidth: option == o ? 3 : 1))
                            .overlay(alignment: .topTrailing) {
                                if o.isPremium && !factory.subscriptions.isSubscribed {
                                    Image(systemName: "lock.fill").font(.system(size: 10)).padding(4).background(.ultraThinMaterial, in: Circle())
                                }
                            }
                            Text(o.name).font(.caption2).lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(inputImage == nil ? "Choose Photo" : "Choose Another", systemImage: "photo")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)
            if outputImage != nil {
                Button { factory.requirePremium(feature: "save_cutout") { save() } } label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func select(_ o: BGOption) {
        if o.isPremium && !factory.subscriptions.isSubscribed { factory.presentPaywall(placement: "bg_\(o.id)"); return }
        option = o
        if inputImage != nil { Task { await process() } }
    }

    private func load(_ item: PhotosPickerItem) async {
        errorText = nil
        if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
            inputImage = img; outputImage = nil
            await process()
        } else { errorText = "Couldn't load that photo." }
    }

    private func process() async {
        guard let inputImage else { return }
        isProcessing = true; errorText = nil
        defer { isProcessing = false }
        do { outputImage = try await service.removeBackground(from: inputImage, option: option) }
        catch { errorText = "Couldn't find a clear subject — try another photo." }
    }

    private func save() {
        guard let outputImage else { return }
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
    }
}

/// Transparency checkerboard so cutouts are visible.
struct CheckerboardBackground: View {
    var body: some View {
        GeometryReader { geo in
            let s: CGFloat = 12
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                let cols = Int(size.width / s) + 1, rows = Int(size.height / s) + 1
                for r in 0..<rows {
                    for c in 0..<cols where (r + c) % 2 == 0 {
                        ctx.fill(Path(CGRect(x: CGFloat(c) * s, y: CGFloat(r) * s, width: s, height: s)),
                                 with: .color(.gray.opacity(0.3)))
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
