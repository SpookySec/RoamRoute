# Project Report: Roam Route Travel Planner

**Date:** May 5th  
**Project Name:** Roam Route  
**Developer:** [Your Name]  
**Platform:** Flutter (Android & Linux support)

---

## 1. Project Overview & Functionalities
Roam Route is a travel itinerary management application designed to help users organize their trips by bridging the gap between simple text notes and geographic visualization.

### Key Functionalities Implemented:
*   **Trip Management:** Users can create, view, edit, and delete trip itineraries.
*   **Categorization:** Automated sorting of trips into "Upcoming" and "Past" categories based on travel dates.
*   **Multi-Stop Itineraries:** Support for adding multiple "Stops" to a single destination.
*   **Map Visualization:** Integration of Google Maps to display markers for every stop and draw the travel path (Polylines).
*   **Location Intelligence:** Real-time location autocomplete using the Google Places SDK.
*   **Itinerary Sharing:** Ability to export trip details to other apps (Email, WhatsApp, etc.).

---

## 2. Backend & Data Source Integration
The application follows a local-first architecture to ensure reliability during travel with intermittent internet access.

*   **Primary Data Source:** **SQLite** (via `sqflite`). A relational database is used to store `trips` with a schema supporting destinations, dates, notes, and a JSON-encoded list of stops.
*   **Persistent Settings:** **Shared Preferences** is used for light-weight data such as user preferences and onboarding states.
*   **External APIs:** 
    *   **Google Places SDK:** Integrated at the native Android level for location suggestions.
    *   **Geocoding API:** Used to translate string-based destinations into geographic coordinates (`LatLng`) for map rendering.

---

## 3. CRUD Operations
The project demonstrates full CRUD (Create, Read, Update, Delete) capabilities through the `DatabaseService` class:

*   **Create:** The `AddTripScreen` captures user input and invokes `createTrip(Trip trip)`, inserting a new row into the SQLite database.
*   **Read:** The `TripsListScreen` uses reactive queries (`getTripsByStatus`) to populate the UI. The `TripDetailScreen` fetches specific trip data by ID.
*   **Update:** Users can modify any existing trip. The `updateTrip` method ensures that changes to notes or stops are persisted.
*   **Delete:** Includes a "Delete with Undo" pattern. When a trip is removed via `deleteTrip(id)`, a SnackBar allows the user to restore the data immediately, enhancing user experience.

---

## 4. Key Flutter Components & Packages
The following libraries were essential in achieving the app's functionality:

| Package | Purpose |
| :--- | :--- |
| `google_maps_flutter` | Interactive map rendering and marker management. |
| `sqflite` | Local relational database persistence. |
| `geocoding` | Address-to-Coordinate translation. |
| `share_plus` | Native sharing capabilities for itineraries. |
| `shared_preferences` | User setting persistence. |
| `cupertino_icons` | iOS-style iconography for a polished cross-platform look. |

---

## 5. Significant Technical Challenge
**Challenge: Integrating Google Places Autocomplete via Platform Channels.**

While Flutter provides many plugins, direct integration with the Google Places SDK for real-time suggestions required a **Platform Channel** implementation. 

**Solution:**
I implemented a `MethodChannel` named `roam_route/places`. 
1.  **Dart Side:** Created a debounced search bar that sends text queries to the host platform.
2.  **Android Side (Java):** Modified `MainActivity.java` to initialize the `PlacesClient` and handle the `findAutocompletePredictions` request.
3.  **Data Parsing:** Resulting predictions are passed back to Dart as a `List<Map<String, String>>`, allowing for a seamless "type-to-suggest" experience that feels native.

---

## 6. Remaining Features & Roadmap
While the core functionality is stable, the following features are planned for the next phase:

*   **Route Optimization:** An algorithm to reorder stops automatically based on the shortest geographic distance.
*   **Budget Tracker:** Adding a financial layer to each trip to track expenses per stop.
*   **Offline Map Caching:** Allowing users to download map tiles for areas with no data coverage.
*   **Photo Gallery:** Integration with the device camera to attach "Memories" (photos) to past trips.
