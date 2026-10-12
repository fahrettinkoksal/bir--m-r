/// Tatil turu paketleri (D-083).
///
/// **Neden var:** Faho istedi — "seyahatte tatil yap ve taşın diye 2 menü
/// olsun; tatil yapta paketler olsun, doğu turu karadeniz turu gibi".
/// Seyahat tek bir şehre gidip gelmekten ibaretti.
///
/// Paketler Türkiye'de gerçekten satılan tur türlerine karşılık gelir
/// (Karadeniz, Doğu, GAP, Ege, Akdeniz, Kapadokya). Gezilen şehirler
/// oyunun **kendi şehir listesinden** seçilir; oyunda bulunmayan bir il
/// tur programına yazılmaz.
///
/// Fiyatlar 2026 ölçeğindedir (D-053) ve yurt içi paket turların gerçek
/// aralığına dayanır; tek tek tutarlar `prototypeOnly` (Q-121).
library;

import 'package:flutter/material.dart';

/// Bir tur paketi.
class TourPackage {
  const TourPackage({
    required this.id,
    required this.label,
    required this.description,
    required this.cities,
    required this.nights,
    required this.prototypeOnlyCost,
    required this.icon,
  });

  final String id;
  final String label;
  final String description;

  /// Turda gezilen şehirler; hepsi oyunun şehir listesindedir.
  final List<String> cities;

  /// Kaç gece sürdüğü.
  final int nights;

  /// prototypeOnly: kişi başı paket ücreti (₺).
  final int prototypeOnlyCost;

  final IconData icon;

  /// Turun ana durağı: gezi kaydına bu şehir yazılır.
  String get mainCity => cities.first;
}

const List<TourPackage> kTourPackages = <TourPackage>[
  TourPackage(
    id: 'kapadokya',
    label: 'Kapadokya Turu',
    description: 'Peribacaları, yeraltı şehri ve sabah balonları.',
    cities: <String>['Kayseri', 'Konya'],
    nights: 3,
    prototypeOnlyCost: 29000,
    icon: Icons.terrain_rounded,
  ),
  TourPackage(
    id: 'ege',
    label: 'Ege Turu',
    description: 'Antik kentler, zeytinlikler ve akşamüstü sahil.',
    cities: <String>['İzmir', 'Aydın', 'Denizli'],
    nights: 4,
    prototypeOnlyCost: 38000,
    icon: Icons.waves_rounded,
  ),
  TourPackage(
    id: 'akdeniz',
    label: 'Akdeniz Turu',
    description: 'Deniz, kanyon ve gece yarısı hâlâ sıcak hava.',
    cities: <String>['Antalya', 'Adana'],
    nights: 5,
    prototypeOnlyCost: 42000,
    icon: Icons.beach_access_rounded,
  ),
  TourPackage(
    id: 'gap',
    label: 'GAP Turu',
    description: 'Güneydoğu: taş evler, uzun sofralar, sıcak rüzgâr.',
    cities: <String>['Gaziantep', 'Diyarbakır', 'Malatya'],
    nights: 5,
    prototypeOnlyCost: 44000,
    icon: Icons.wb_sunny_rounded,
  ),
  TourPackage(
    id: 'karadeniz',
    label: 'Karadeniz Turu',
    description: 'Yayla, sis ve her öğün çay.',
    cities: <String>['Trabzon', 'Samsun', 'Amasya'],
    nights: 6,
    prototypeOnlyCost: 48000,
    icon: Icons.forest_rounded,
  ),
  TourPackage(
    id: 'dogu',
    label: 'Doğu Turu',
    description: 'Uzun tren yolu, yüksek dağlar ve çok soğuk sabahlar.',
    cities: <String>['Erzurum', 'Van', 'Sivas'],
    nights: 7,
    prototypeOnlyCost: 62000,
    icon: Icons.ac_unit_rounded,
  ),
];

TourPackage? tourById(String id) {
  for (final TourPackage t in kTourPackages) {
    if (t.id == id) return t;
  }
  return null;
}
