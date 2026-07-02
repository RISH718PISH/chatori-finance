/// A named money bucket used for breakdowns (category, party, P&L lines).
class Bucket {
  final String label;
  final int paise;
  const Bucket(this.label, this.paise);
}
