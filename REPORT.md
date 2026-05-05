# Project Report: Roam Route Travel Planner

**Date:** 4/5/2026
**Project Name:** Roam Route
**Team:** Abdulrahman Abu Hurirah, Bilal Al Tabbaa, Yazeed Ashour
**Platform:** Flutter

---

## 1. Project Overview & Functionalities
Roam Route is a travel itinerary app built to make trip planning feel more intuitive. It sits somewhere between basic note-taking and full-on map navigation, helping users organize their journeys while actually seeing them laid out geographically.

### What it can do so far:
- **Trip Management:** Create, view, edit, and delete trips with ease.
- **Smart Categorization:** Trips are automatically sorted into “Upcoming” or “Past” based on their dates.
- **Multi-Stop Planning:** Add multiple stops within a single destination to map out more detailed itineraries.
- **Map Visualization:** Google Maps integration lets users see every stop as a marker, with routes connected using polylines.
- **Location Intelligence:** Real-time autocomplete makes searching for places fast and accurate.
- **Easy Sharing:** Trips can be exported and shared through apps like Email or WhatsApp.

---

## 2. Backend & Data Integration
The app uses a **local-first approach**, which makes it reliable even when internet access is spotty—something that’s pretty common while traveling.

- **Main Data Storage:** SQLite (via `sqflite`) stores all trip data, including destinations, dates, notes, and stops (saved as JSON).
- **Lightweight Storage:** Shared Preferences handles smaller bits like user settings and onboarding progress.
- **External APIs:**
    - Google Places SDK for location suggestions
    - Geocoding API to turn place names into coordinates for map display

---

## 3. CRUD Functionality
All core database operations are handled through the `DatabaseService` class:

- **Create:** Users add trips through `AddTripScreen`, which saves them using `createTrip`.
- **Read:** Trip lists are dynamically loaded based on their status, and individual trips can be viewed in detail.
- **Update:** Any part of a trip—notes, stops, dates—can be edited and saved.
- **Delete:** There’s a “Delete with Undo” feature, so if something gets removed by accident, it can be quickly restored via a SnackBar.

---

## 4. Core Flutter Packages

| Package | Role |
|--------|------|
| `google_maps_flutter` | Displays maps and manages markers |
| `sqflite` | Handles local database storage |
| `geocoding` | Converts addresses into coordinates |
| `share_plus` | Enables sharing across apps |
| `shared_preferences` | Stores user settings |
| `cupertino_icons` | Adds iOS-style visuals |

---

## 5. Biggest Technical Challenge
One of the trickiest parts was integrating **Google Places Autocomplete** using platform channels.

Flutter has plenty of plugins, but getting real-time suggestions from the native Google Places SDK required a custom setup.

### How it was handled:
- On the **Dart side**, a debounced search bar sends user input through a `MethodChannel` (`roam_route/places`).
- On the **Android side**, `MainActivity.java` was updated to initialize `PlacesClient` and process autocomplete requests.
- The results are sent back as structured data, making the suggestions feel smooth and native within the app.

---

## 6. What’s Next
The foundation is solid, but there’s still a lot planned:

- **Route Optimization:** Automatically reorder stops for the most efficient path
- **Budget Tracking:** Add expense tracking for each trip
- **Offline Maps:** Download map data for use without internet
- **Photo Memories:** Attach photos to trips for a more personal touch  