import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class ApiException implements Exception {

  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  factory ApiService() => _instance;
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();

  final String _baseUrl = AppConfig.apiBaseUrl;
  
  SupabaseClient get _supabase => Supabase.instance.client;

  // Get auth headers
  Future<Map<String, String>> _getHeaders() async {
    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Generic GET request
  Future<dynamic> get(final String endpoint, {final Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Generic POST request
  Future<dynamic> post(final String endpoint, {final dynamic body}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Generic PUT request
  Future<dynamic> put(final String endpoint, {final dynamic body}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Generic PATCH request
  Future<dynamic> patch(final String endpoint, {final dynamic body}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(final String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.delete(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Handle response
  dynamic _handleResponse(final http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else {
      var message = 'Unknown error';

      if (body is Map<String, dynamic>) {
        if (body['message'] is String) {
          message = body['message'] as String;
        }

        final errorObj = body['error'];
        if (errorObj is String) {
          message = errorObj;
        } else if (errorObj is Map<String, dynamic>) {
          if (errorObj['message'] is String) {
            message = errorObj['message'] as String;
          }

          final details = errorObj['details'];
          if (details is List && details.isNotEmpty) {
            final first = details.first;
            if (first is Map<String, dynamic>) {
              final detailMessage = first['message'];
              final field = first['field'];
              if (detailMessage is String && field is String) {
                message = '$detailMessage ($field)';
              } else if (detailMessage is String) {
                message = detailMessage;
              }
            }
          }
        }
      }

      throw ApiException(message, statusCode: statusCode);
    }
  }

  // Upload file to Supabase Storage
  Future<String> uploadFile({
    required final String bucket,
    required final String path,
    required final List<int> fileBytes,
    final String? contentType,
  }) async {
    try {
      await _supabase.storage.from(bucket).uploadBinary(
        path,
        fileBytes is Uint8List ? fileBytes : Uint8List.fromList(fileBytes),
        fileOptions: FileOptions(
          contentType: contentType ?? 'application/octet-stream',
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw ApiException('Failed to upload file: $e');
    }
  }

  // Delete file from Supabase Storage
  Future<void> deleteFile({
    required final String bucket,
    required final String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw ApiException('Failed to delete file: $e');
    }
  }

  // Supabase query helpers
  Future<List<Map<String, dynamic>>> query(
    final String table, {
    final String? select,
    final Map<String, dynamic>? filters,
    final String? orderBy,
    final bool ascending = false,
    final int? limit,
    final int? offset,
  }) async {
    try {
      dynamic query = _supabase.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        filters.forEach((final key, final value) {
          if (value != null) {
            query = query.eq(key, value);
          }
        });
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply pagination
      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw ApiException('Query failed: $e');
    }
  }

  // Insert data
  Future<Map<String, dynamic>> insert(
    final String table,
    final Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      throw ApiException('Insert failed: $e');
    }
  }

  // Update data
  Future<Map<String, dynamic>> update(
    final String table,
    final String id,
    final Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      throw ApiException('Update failed: $e');
    }
  }

  // Delete data
  Future<void> deleteRecord(final String table, final String id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
    } catch (e) {
      throw ApiException('Delete failed: $e');
    }
  }

  // Get single record
  Future<Map<String, dynamic>?> getById(final String table, final String id) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();
      return response;
    } catch (e) {
      throw ApiException('Get failed: $e');
    }
  }

  // Subscribe to realtime changes
  RealtimeChannel subscribe(
    final String table, {
    required final void Function(Map<String, dynamic> payload) onInsert,
    final void Function(Map<String, dynamic> payload)? onUpdate,
    final void Function(Map<String, dynamic> payload)? onDelete,
  }) {
    return _supabase
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          callback: (final payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: table,
          callback: (final payload) => onUpdate?.call(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: table,
          callback: (final payload) => onDelete?.call(payload.oldRecord),
        )
        .subscribe();
  }

  // Unsubscribe from channel
  void unsubscribe(final RealtimeChannel channel) {
    _supabase.removeChannel(channel);
  }

  // Upload multipart/form-data (for file uploads)
  Future<dynamic> postMultipart(
    final String endpoint,
    final Map<String, String> fields, {
    final List<http.MultipartFile>? files,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final session = _supabase.auth.currentSession;
      final token = session?.accessToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add fields
      request.fields.addAll(fields);

      // Add files
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }
}
