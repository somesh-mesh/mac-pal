// Represents a single Mac app returned by GET /apps
class AppModel {
  final String name; // "Safari", "Xcode", "Final Cut Pro"
  final String path; // "/Applications/Safari.app"

  const AppModel({required this.name, required this.path});

  // Converts the JSON map from the server into an AppModel object
  // Server sends: { "name": "Safari", "path": "/Applications/Safari.app" }
  factory AppModel.fromJson(Map<String, dynamic> json) => AppModel(
        name: json['name'] as String,
        path: json['path'] as String,
      );
}
