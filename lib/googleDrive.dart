import 'dart:io';

import 'package:galileo2/secureStorage.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

var id = new ClientId(
    "728272375943-r61vn2fved203qh8m4ag7r55ts9s1inf.apps.googleusercontent.com",
    "");

const _scopes = [ga.DriveApi.DriveFileScope];

class GoogleDrive {
  final storage = SecureStorage();
  //Get Authenticated Http Client
  Future<http.Client> getHttpClient() async {
    var credentials = await storage.getCredentials();
    print(credentials);

    if (credentials == null) {
      //Needs user authentication
      //Save Credentials
      var authClient = await clientViaUserConsent(id, _scopes, (url) {
        //Open Url in Browser
        launch(url);
      });
      print("test2");

      await storage.saveCredentials(authClient.credentials.accessToken,
          authClient.credentials.refreshToken);
      return authClient;
    } else {
      print(DateTime.tryParse(credentials["expiry"]));
      //Already authenticated
      print("check");
      return authenticatedClient(
          http.Client(),
          AccessCredentials(
              AccessToken(credentials["type"], credentials["data"],
                  DateTime.tryParse(credentials["expiry"])),
              credentials["refreshToken"],
              _scopes));
    }
  }

  //Upload File
  Future upload(File file) async {
    var client = await getHttpClient();

    var drive = ga.DriveApi(client);

    try {
      var response = await drive.files.create(
          ga.File()..name = p.basename(file.absolute.path),
          uploadMedia: ga.Media(file.openRead(), file.lengthSync()));
      return response;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
