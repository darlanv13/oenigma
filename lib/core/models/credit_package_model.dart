// lib/core/models/credit_package_model.dart
// Conformidade com o PRD v1.0 (README.md - Seções 7.6 e 8.1)

class CreditPackageModel {
  final String id;
  final String name;
  final int credits;
  final double price;
  final String badge;
  final String description;

  const CreditPackageModel({
    required this.id,
    required this.name,
    required this.credits,
    required this.price,
    required this.badge,
    required this.description,
  });

  static const List<CreditPackageModel> officialPackages = [
    CreditPackageModel(
      id: 'inicial',
      name: 'Inicial',
      credits: 1,
      price: 5.00,
      badge: 'EXPERIMENTAR',
      description: 'Ideal para lançar sua primeira experiência rápida.',
    ),
    CreditPackageModel(
      id: 'basico',
      name: 'Básico',
      credits: 5,
      price: 19.90,
      badge: 'POPULAR',
      description: 'Perfeito para criadores que publicam missões semanais.',
    ),
    CreditPackageModel(
      id: 'criador',
      name: 'Criador',
      credits: 15,
      price: 49.90,
      badge: 'MELHOR CUSTO',
      description: 'Excelente custo-benefício para engajar sua comunidade todo mês.',
    ),
    CreditPackageModel(
      id: 'avancado',
      name: 'Avançado',
      credits: 50,
      price: 129.90,
      badge: 'PRO',
      description: 'Para grandes campanhas, caças ao tesouro e desafios simultâneos.',
    ),
  ];
}
