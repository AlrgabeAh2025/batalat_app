/// Batalat — CMS models + providers
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/network/api_client.dart';

class SiteContactInfo {
  final String phone;
  final String whatsapp;
  final String email;
  final String address;
  final String workingHours;
  final String facebookUrl;
  final String instagramUrl;
  final String tiktokUrl;

  const SiteContactInfo({
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.address = '',
    this.workingHours = '',
    this.facebookUrl = '',
    this.instagramUrl = '',
    this.tiktokUrl = '',
  });

  factory SiteContactInfo.fromJson(Map<String, dynamic> json) {
    return SiteContactInfo(
      phone: json['phone'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      workingHours: json['working_hours'] as String? ?? '',
      facebookUrl: json['facebook_url'] as String? ?? '',
      instagramUrl: json['instagram_url'] as String? ?? '',
      tiktokUrl: json['tiktok_url'] as String? ?? '',
    );
  }
}

class LegalPageContent {
  final String slug;
  final String title;
  final String body;

  const LegalPageContent({
    required this.slug,
    required this.title,
    required this.body,
  });

  factory LegalPageContent.fromJson(Map<String, dynamic> json) {
    return LegalPageContent(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

class FaqItem {
  final int id;
  final String question;
  final String answer;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] as int,
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

final contactProvider =
    FutureProvider.autoDispose<SiteContactInfo>((ref) async {
  try {
    final res = await ApiClient().dio.get('/cms/contact/');
    return SiteContactInfo.fromJson(Map<String, dynamic>.from(res.data as Map));
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final termsProvider =
    FutureProvider.autoDispose<LegalPageContent>((ref) async {
  try {
    final res = await ApiClient().dio.get('/cms/pages/terms/');
    return LegalPageContent.fromJson(Map<String, dynamic>.from(res.data as Map));
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final faqsProvider = FutureProvider.autoDispose<List<FaqItem>>((ref) async {
  try {
    final res = await ApiClient().dio.get('/cms/faqs/');
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? []) : <dynamic>[]);
    return list
        .whereType<Map>()
        .map((e) => FaqItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});
