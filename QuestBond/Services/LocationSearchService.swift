import MapKit

final class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = "" {
        didSet {
            completer.queryFragment = query
        }
    }

    @Published private(set) var suggestions: [String] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let nextSuggestions = completer.results.prefix(5).map { result in
            [result.title, result.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
        }

        DispatchQueue.main.async {
            self.suggestions = nextSuggestions
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.suggestions = []
        }
    }
}
