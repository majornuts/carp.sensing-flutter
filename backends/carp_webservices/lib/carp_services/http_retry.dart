/*
 * Copyright 2020-2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of carp_services;

/// The HTTP Retry method.
final HTTPRetry httpr = HTTPRetry();

/// A MultipartFile class which support cloning of the file for re-submission
/// of POST request.
class MultipartFileRecreatable extends http.MultipartFile {
  final String filePath;

  MultipartFileRecreatable(
    this.filePath,
    super.field,
    super.stream,
    super.length, {
    super.filename,
    super.contentType,
  });

  /// Creates a new [MultipartFileRecreatable] from a file specified by
  /// the [filePath].
  factory MultipartFileRecreatable.fromFileSync(String filePath) {
    final file = File(filePath);
    final length = file.lengthSync();
    final stream = file.openRead();
    var name = file.path.split('/').last;

    return MultipartFileRecreatable(
      filePath,
      'file',
      stream,
      length,
      filename: name,
    );
  }

  /// Make a clone of this [MultipartFileRecreatable].
  MultipartFileRecreatable clone() =>
      MultipartFileRecreatable.fromFileSync(filePath);
}

/// A class wrapping all HTTP operations (GET, POST, PUT, DELETE) in a retry manner.
///
/// In case of network problems ([SocketException] or [TimeoutException]),
/// this method will retry the HTTP operation N=15 times, with an increasing
/// delay time as 2^(N+1) * 5 secs (20, 40, , ..., 10.240).
/// I.e., maximum retry time is ca. three hours.
class HTTPRetry {
  var client = http.Client();

  /// Sends an generic HTTP [MultipartRequest].
  Future<http.StreamedResponse> send(http.MultipartRequest request) async {
    http.MultipartRequest sending = request;

    return await retry(
      () => client.send(sending).timeout(Duration(seconds: 20)),
      delayFactor: Duration(seconds: 5),
      maxAttempts: 15,
      retryIf: (e) => e is SocketException || e is TimeoutException,
      onRetry: (e) {
        print('${e.runtimeType} - Retrying to SEND ${request.url}');

        // when retrying sending form data, the request needs to be cloned
        // see e.g. >> https://github.com/flutterchina/dio/issues/482
        sending = http.MultipartRequest(request.method, request.url);
        sending.headers.addAll(request.headers);
        sending.fields.addAll(request.fields);

        request.files.forEach((file) {
          if (file is MultipartFileRecreatable) {
            sending.files.add(file.clone());
          }
        });
      },
    );
  }

  /// Sends an HTTP GET request with the given [headers] to the given [url].
  Future<http.Response> get(String url, {Map<String, String>? headers}) async =>
      await retry(
        () => client
            .get(
              Uri.parse(Uri.encodeFull(url)),
              headers: headers,
            )
            .timeout(Duration(seconds: 10)),
        delayFactor: Duration(seconds: 5),
        maxAttempts: 15,
        retryIf: (e) => e is SocketException || e is TimeoutException,
        onRetry: (e) => print('${e.runtimeType} - Retrying to GET $url'),
      );

  /// Sends an HTTP POST request with the given [headers] and [body] to the given [url].
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    body,
    Encoding? encoding,
  }) async {
    // calling the http POST method using the retry approach
    final http.Response response = await retry(
      () => client
          .post(
            Uri.parse(Uri.encodeFull(url)),
            headers: headers,
            body: body,
            encoding: encoding,
          )
          .timeout(Duration(seconds: 10)),
      delayFactor: Duration(seconds: 5),
      maxAttempts: 15,
      retryIf: (e) => e is SocketException || e is TimeoutException,
      onRetry: (e) => print('${e.runtimeType} - Retrying to POST $url'),
    );
    return response;
  }

  /// Sends an HTTP PUT request with the given [headers] and [body] to the given [url].
  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    body,
    Encoding? encoding,
  }) async {
    // calling the http PUT method using the retry approach
    final http.Response response = await retry(
      () => client
          .put(
            Uri.parse(Uri.encodeFull(url)),
            headers: headers,
            body: body,
            encoding: encoding,
          )
          .timeout(Duration(seconds: 10)),
      delayFactor: Duration(seconds: 5),
      maxAttempts: 15,
      retryIf: (e) => e is SocketException || e is TimeoutException,
      onRetry: (e) => print('${e.runtimeType} - Retrying to PUT $url'),
    );
    return response;
  }

  /// Sends an HTTP DELETE request with the given [headers] to the given [url].
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    // calling the http DELETE method using the retry approach
    final http.Response response = await retry(
      () => client
          .delete(
            Uri.parse(Uri.encodeFull(url)),
            headers: headers,
          )
          .timeout(Duration(seconds: 15)),
      delayFactor: Duration(seconds: 5),
      maxAttempts: 15,
      retryIf: (e) => e is SocketException || e is TimeoutException,
      onRetry: (e) => print('${e.runtimeType} - Retrying to DELETE $url'),
    );
    return response;
  }
}
