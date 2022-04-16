<p>
  <img width="100" src="https://raw.githubusercontent.com/fluttertools/flutter.space/main/assets/space_icon.svg">
</p>

# flutter.space

API for a flat dataset for different interesting Flutter/Dart information.

## Important

```text
This is an experimental API, and the endpoints might still change. If you would like to use this data in production, please open an issue, so we can provide timeline.
```

## Use as an API

We leverage GitHub CDN infrastructure in order to provide the flat data as API endpoints. These endpoints are currently being used on [FVM](https://github.com/fluttertools/fvm) & [Flutter Sidekick](https://github.com/fluttertools/sidekick)

## Available Flat Data

- Flutter releases (MacOS, Windows & Linux)
- Flutter Favorites (Official Flutter Favorites)
- Github trending Repositories (daily/weekly/monthly)
- Pub.dev packages
  - Most popular
  - Most liked
  - Recently updated
  - Recently created
  - Google packages

## API Request

### Curl
```curl
curl --location --request GET 'http://api.flutter.space/ENDPOINT_HERE.json'
```

### Dart

```dart
var request = http.Request('GET', Uri.parse('http://api.flutter.space/ENDPOINT_HERE.json'));


http.StreamedResponse response = await request.send();

if (response.statusCode == 200) {
  print(await response.stream.bytesToString());
}
else {
  print(response.reasonPhrase);
}

```

## Flutter Releases

Currently does a daily snapshot of the Flutter Releases JSON for all platforms.

### Endpoints

macos - https://api.flutter.space/v1/releases/macos.json

windows - https://api.flutter.space/v1/releases/windows.json

linux - https://api.flutter.space/v1/releases/linux.json

### Browse data

macos - https://flatgithub.com/fluttertools/flutter.space?filename=releases_macos.json

windows - https://flatgithub.com/fluttertools/flutter.space?filename=releases_windows.json

linux - https://flatgithub.com/fluttertools/flutter.space?filename=releases_linux.json

## Flutter Favorites

A json with all Flutter Favorites including package information.

### Endpoints

https://api.flutter.space/v1/pub/flutter-favorites.json

### Browse data

https://flatgithub.com/fluttertools/flutter.space?filename=flutter-favorites.json

## Github Dart Trending Repos

A json with a trending Github Repos in Dart in the last month.

### Endpoints

today - https://api.flutter.space/v1/trending/today.json

week - https://api.flutter.space/v1/trending/week.json

month - https://api.flutter.space/v1/trending/month.json


### Browse data

today - https://flatgithub.com/fluttertools/flutter.space?filename=trending-repository-today.json

week - https://flatgithub.com/fluttertools/flutter.space?filename=trending-repository-week.json

month - https://flatgithub.com/fluttertools/flutter.space?filename=trending-repository-month.json

## Google Packages

Official Google packages on pub.dev

### Endpoints

https://api.flutter.space/v1/pub/google-packages.json

### Browse data

https://flatgithub.com/fluttertools/flutter.space?filename=google-packages.json


## Pub.dev Packages

### Endpoints

Popular: https://api.flutter.space/v1/pub/most-popular.json

Most liked: https://api.flutter.space/v1/pub/most-liked.json

Recently created: https://api.flutter.space/v1/pub/recently-created.json

Recently updated: https://api.flutter.space/v1/pub/recently-updated.json


### Browse data

Popular: https://flatgithub.com/fluttertools/flutter.space?filename=packages-most-popular.json

Most liked: https://flatgithub.com/fluttertools/flutter.space?filename=packages-most-liked.json

Recently created: https://flatgithub.com/fluttertools/flutter.space?filename=packages-recently-created.json

Recently updated: https://flatgithub.com/fluttertools/flutter.space?filename=packages-recently-updated.json

