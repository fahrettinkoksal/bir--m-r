/// Anne ve babanın birbirleriyle olan durumu (D-013).
///
/// Bu durum akrabalıktan ve haneden ayrıdır: ayrı/boşanmış ebeveynlerin
/// ikisi birden oyuncunun hanesinde yaşamaz.
enum ParentalStatus {
  evli('Evli'),
  birlikte('Birlikte yaşıyor'),
  ayri('Ayrı yaşıyor'),
  bosanmis('Boşanmış');

  const ParentalStatus(this.label);

  final String label;

  bool get birlikteMi => this == ParentalStatus.evli || this == ParentalStatus.birlikte;
}
