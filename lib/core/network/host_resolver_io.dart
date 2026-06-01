import 'dart:io';

Future<String> resolveHostForDiagnostics(String host) async {
  final addresses = await InternetAddress.lookup(host);
  if (addresses.isEmpty) {
    return 'DNS не вернул адреса';
  }

  return addresses.map((address) => address.address).join(', ');
}
