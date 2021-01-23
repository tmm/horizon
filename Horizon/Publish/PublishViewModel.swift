// By Tom Meagher on 1/23/21 at 14:28

import SwiftUI
import Combine

class PublishViewModel: ObservableObject, Identifiable {
    private(set) var store: Store
    private let onClose: () -> Void
    private var disposables = Set<AnyCancellable>()

    @Published
    var networkActive = false
    
    @Published
    var entry = ""
    
    @Published
    var selectedJournalId: Int = 0
    
    @Published
    var journals = [Journal]()
    
    @Published
    var isFileBrowserOpen = false
    
    @Published
    var file: File?

    var wordCount: Int { entry.split { $0 == " " || $0.isNewline }.count }

    init(
        store: Store,
        onClose: @escaping () -> Void
    ) {
        self.store = store
        self.onClose = onClose
    }

    func addMedia() {
        isFileBrowserOpen = true
    }

    func attachMedia(_ result: Result<URL, Error>) {
        do {
            let fileUrl = try result.get()
            guard fileUrl.startAccessingSecurityScopedResource() else { return }

            // Get file data
            guard let data = try? Data(contentsOf: fileUrl) else {
                print("Unable to read data")
                return
            }

            // Get mime type
            guard
                let extUTI = UTTypeCreatePreferredIdentifierForTag(
                    kUTTagClassFilenameExtension,
                    fileUrl.pathExtension as CFString,
                    nil)?.takeUnretainedValue()
            else { return }
            guard
                let mimeUTI = UTTypeCopyPreferredTagWithClass(extUTI, kUTTagClassMIMEType)
             else { return }
            let mimeType = mimeUTI.takeRetainedValue() as String

            file = File(name: fileUrl.lastPathComponent, data: data, mimeType: mimeType)
            fileUrl.stopAccessingSecurityScopedResource()
        } catch {
            print(error.localizedDescription)
        }
    }

    func cancel() {
        reset()
    }

    func discardMedia() {
        file = nil
    }

    func fetch() {
        guard let token = store.token else { return }

        self.networkActive = true
        
        Futureland
            .journals(token: token)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
                self.networkActive = false
            }, receiveValue: { journals in
                let sortedJournals = journals.sorted { $0.lastEntryAt > $1.lastEntryAt }
                print(sortedJournals)
                self.journals = sortedJournals

                // Check if a journal is already selected
                let selectedJournal = sortedJournals.first { $0.id == self.selectedJournalId }
                if selectedJournal != nil { return }

                // Select first journal if none are selected
                guard let journal = sortedJournals.first else { return }
                self.selectedJournalId = journal.id
            })
            .store(in: &disposables)
    }

    func publish() {
        guard let token = store.token else { return }
        
        self.networkActive = true
        
        Futureland
            .createEntry(
                token: token,
                notes: entry,
                journalId: selectedJournalId,
                file: file
            )
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                    fatalError(error.localizedDescription)
                }
                self.networkActive = false
            }, receiveValue: { entry in
                print(entry)
                self.reset()
            })
            .store(in: &disposables)
    }

    func reset() {
        self.entry = ""
        self.file = nil
        self.onClose()
    }
}