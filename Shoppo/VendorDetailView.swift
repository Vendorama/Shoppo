import SwiftUI
import SDWebImageSwiftUI
import MapKit
import CoreLocation

struct VendorDetailView: View {
    let vendor: Vendor

    // Geocoding/map state
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var isGeocoding: Bool = false
    @State private var geocodeError: String?
    // iOS 14–16 fallback region binding
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -36.8485, longitude: 174.7633), // Auckland default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 12) {
                    if let thumb = vendor.thumb, let url = apiURL(thumb) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary, lineWidth: 1).opacity(0.5))
                            .shadow(color: .black.opacity(0.06), radius: 4, x: -2, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 72, height: 72)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(vendor.name ?? "Store")
                                .font(.title3.weight(.semibold))
                            if (vendor.licence ?? 0) != 0 {
                                Image("verified")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                //checkmark.seal.fill
                            }
                            // TODO
                            // clicks likes
                        }
                        if let urlStr = vendor.url, let host = URL(string: urlStr)?.host {
                            Text(host)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                // Description
                if let desc = vendor.description, !desc.isEmpty {
                    Text(desc)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Contact
                if let email = vendor.email, !email.isEmpty {
                    Link(destination: URL(string: "mailto:\(email)")!) {
                        Label(email, systemImage: "envelope")
                    }
                }
                if let phone = vendor.phone, !phone.isEmpty {
                    Link(destination: URL(string: "tel:\(phone)")!) {
                        Label(phone, systemImage: "phone")
                    }
                }

                // Address (only if address1 present)
                let addr1 = (vendor.address1 ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let addr2 = (vendor.address2 ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let city = (vendor.city ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let postcode = (vendor.postcode ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                if !addr1.isEmpty {
                    // NZ-style display lines:
                    // address1
                    // address2 (optional)
                    // city postcode (optional)
                    let cityPostcodeLine: String = {
                        switch (city.isEmpty, postcode.isEmpty) {
                        case (false, false): return "\(city) \(postcode)"
                        case (false, true):  return city
                        case (true, false):  return postcode
                        case (true, true):   return ""
                        }
                    }()
                    let displayLines = [addr1, addr2, cityPostcodeLine].filter { !$0.isEmpty }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Address")
                            .font(.headline)
                        Text(displayLines.joined(separator: "\n"))
                            .font(.body)
                            .foregroundStyle(.secondary)

                        // Map section
                        mapSection
                    }
                }
            }
            .padding()
        }
        .navigationTitle(vendor.name ?? "Store")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await geocodeIfNeeded()
        }
    }

    // MARK: - Map section

    @ViewBuilder
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isGeocoding {
                HStack {
                    ProgressView()
                    Text("Locating on map…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else if let coordinate {
                if #available(iOS 17.0, *) {
                    // New Map API with initial position and Marker
                    Map(initialPosition: .region(regionFor(coordinate))) {
                        Marker(vendor.name ?? "Location", coordinate: coordinate)
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onAppear {
                        region = regionFor(coordinate)
                    }
                } else {
                    // Fallback for iOS 14–16
                    Map(coordinateRegion: $region, annotationItems: [AnnotatedPin(title: vendor.name ?? "Location", coordinate: coordinate)]) { item in
                        MapMarker(coordinate: item.coordinate, tint: .red)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onAppear {
                        region = regionFor(coordinate)
                    }
                }

                // Open in Apple Maps
                if let mapItem = mkMapItem(for: coordinate) {
                    Button {
                        mapItem.openInMaps(launchOptions: [
                            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
                            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                        ])
                    } label: {
                        Label("Open in Maps", systemImage: "map")
                    }
                    .buttonStyle(.borderless)
                    .font(.subheadline)
                }
            } else if geocodeError != nil {
                // Silent failure by default; uncomment to show a hint:
                // Text("Couldn’t locate this address on the map.")
                //     .font(.footnote)
                //     .foregroundStyle(.secondary)
                EmptyView()
            }
        }
    }

    private func regionFor(_ coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
    }

    private func mkMapItem(for coordinate: CLLocationCoordinate2D) -> MKMapItem? {
        let placemark = MKPlacemark(
            coordinate: coordinate,
            addressDictionary: nil
        )
        let item = MKMapItem(placemark: placemark)
        item.name = vendor.name ?? "Location"
        // Provide the same NZ-style address string so Maps shows it nicely
        if let formatted = formattedGeocodeAddress() {
            item.phoneNumber = vendor.phone // optional: include phone
            item.url = vendor.url.flatMap { URL(string: $0) }
            // Note: MKMapItem doesn’t expose a setter for full postal address string,
            // but passing name + coordinate is sufficient to show a pin.
            // The formatted string is used for geocoding; for directions we can use it in a query if needed.
        }
        return item
    }

    // MARK: - Geocoding

    // Comma-separated address for geocoding and external use:
    // address1, address2 (optional), city postcode (optional), New Zealand
    private func formattedGeocodeAddress() -> String? {
        let addr1 = (vendor.address1 ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !addr1.isEmpty else { return nil }
        let addr2 = (vendor.address2 ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let city = (vendor.city ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let postcode = (vendor.postcode ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        let cityPostcode: String? = {
            switch (city.isEmpty, postcode.isEmpty) {
            case (false, false): return "\(city) \(postcode)"
            case (false, true):  return city
            case (true, false):  return postcode
            case (true, true):   return nil
            }
        }()

        var parts: [String] = [addr1]
        if !addr2.isEmpty { parts.append(addr2) }
        if let cp = cityPostcode { parts.append(cp) }
        parts.append("New Zealand")
        return parts.joined(separator: ", ")
    }

    private func formattedAddress() -> String? {
        // Use the same geocode format
        formattedGeocodeAddress()
    }

    private func geocodeIfNeeded() async {
        // Only geocode when we have address1
        guard coordinate == nil, !isGeocoding else { return }
        guard let address = formattedAddress() else { return }

        isGeocoding = true
        geocodeError = nil
        defer { isGeocoding = false }

        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            if let location = placemarks.first?.location {
                await MainActor.run {
                    self.coordinate = location.coordinate
                    self.region = regionFor(location.coordinate)
                }
            } else {
                await MainActor.run { self.geocodeError = "No results" }
            }
        } catch {
            await MainActor.run { self.geocodeError = error.localizedDescription }
        }
    }
}

// Helper for iOS 14–16 Map annotations
private struct AnnotatedPin: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
}
