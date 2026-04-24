import 'dart:io';
void main() async {
  var d = Directory('C:/Users/sc/AppData/Local/Pub/Cache/hosted/pub.dev/file_picker-11.0.2/lib');
  if (d.existsSync()) {
    print("Found! Files:");
    for (var m in d.listSync()) {
      print(m.path);
    }
  } else {
    print("Not found at ${d.path}");
  }
}
