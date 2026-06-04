class GoodwillChainSummary {
  final int peopleHelped;
  final int campaignsInfluenced;
  final int creditsPropagated;

  GoodwillChainSummary({
    required this.peopleHelped,
    required this.campaignsInfluenced,
    required this.creditsPropagated,
  });

  factory GoodwillChainSummary.fromJson(Map<String, dynamic> json) {
    return GoodwillChainSummary(
      peopleHelped: json['people_helped'] as int? ?? 0,
      campaignsInfluenced: json['campaigns_influenced'] as int? ?? 0,
      creditsPropagated: json['credits_propagated'] as int? ?? 0,
    );
  }

  // Derived estimate based on campaigns
  int get estimatedReach =>
      peopleHelped +
      (campaignsInfluenced * 20); // Rough proxy for lives reached
}
