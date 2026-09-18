/// Bir kişinin **kendine ait** ekonomik durumu.
///
/// D-013 gereği anne ile babanın maddi durumu birbirinden bağımsızdır;
/// bu yüzden servet hane değil kişi düzeyinde tutulur. Basamak sayısı ve
/// dağılımı prototip içindir, onaylanmış bir ekonomi dengesi değildir.
enum WealthTier {
  cokYoksul('Çok yoksul'),
  yoksul('Dar gelirli'),
  ortaHalli('Orta halli'),
  varlikli('Varlıklı'),
  cokVarlikli('Çok varlıklı');

  const WealthTier(this.label);

  final String label;
}

/// Kişinin çalışma durumu.
///
/// `docs/FAMILY_SYSTEM.md`: "İşsiz/emekli kişiye uydurma meslek gösterilmez."
/// Bu yüzden meslek alanı yalnızca [EmploymentStatus.calisiyor] için doludur.
enum EmploymentStatus {
  calisiyor('Çalışıyor'),
  issiz('İşsiz'),
  emekli('Emekli'),
  evIsleri('Ev işleriyle ilgileniyor'),
  ogrenci('Öğrenci'),
  cocuk('Okul öncesi');

  const EmploymentStatus(this.label);

  final String label;
}
