package com.example.roam_route;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;

import androidx.annotation.NonNull;

import com.google.android.libraries.places.api.Places;
import com.google.android.libraries.places.api.model.AutocompletePrediction;
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest;
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsResponse;
import com.google.android.libraries.places.api.net.PlacesClient;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
	private static final String PLACES_CHANNEL = "roam_route/places";
	private PlacesClient placesClient;

	@Override
	public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
		super.configureFlutterEngine(flutterEngine);
		initializePlacesClient();

		new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), PLACES_CHANNEL)
				.setMethodCallHandler((call, result) -> {
					if ("autocomplete".equals(call.method)) {
						String query = call.argument("query");
						handleAutocomplete(query, result);
					} else {
						result.notImplemented();
					}
				});
	}

	private void initializePlacesClient() {
		if (Places.isInitialized()) {
			placesClient = Places.createClient(this);
			return;
		}

		String apiKey = null;
		try {
			ApplicationInfo appInfo = getPackageManager().getApplicationInfo(
					getPackageName(),
					PackageManager.GET_META_DATA
			);
			Bundle metaData = appInfo.metaData;
			if (metaData != null) {
				apiKey = metaData.getString("com.google.android.geo.API_KEY");
			}
		} catch (PackageManager.NameNotFoundException ignored) {
			apiKey = null;
		}

		if (apiKey != null && !apiKey.trim().isEmpty()) {
			Places.initialize(getApplicationContext(), apiKey);
			placesClient = Places.createClient(this);
		}
	}

	private void handleAutocomplete(String query, MethodChannel.Result result) {
		if (query == null || query.trim().isEmpty()) {
			result.success(new ArrayList<>());
			return;
		}

		if (placesClient == null) {
			result.error("PLACES_NOT_INITIALIZED", "Google Places client is not initialized.", null);
			return;
		}

		FindAutocompletePredictionsRequest request = FindAutocompletePredictionsRequest.builder()
				.setQuery(query.trim())
				.build();

		placesClient.findAutocompletePredictions(request)
				.addOnSuccessListener((FindAutocompletePredictionsResponse response) -> {
					List<Map<String, String>> suggestions = new ArrayList<>();
					for (AutocompletePrediction prediction : response.getAutocompletePredictions()) {
						Map<String, String> item = new HashMap<>();
						item.put("fullText", prediction.getFullText(null).toString());
						CharSequence secondary = prediction.getSecondaryText(null);
						item.put("secondaryText", secondary == null ? "" : secondary.toString());
						item.put("placeId", prediction.getPlaceId());
						suggestions.add(item);
					}
					result.success(suggestions);
				})
				.addOnFailureListener(error ->
						result.error("AUTOCOMPLETE_FAILED", error.getMessage(), null)
				);
	}
}