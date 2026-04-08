class StrongConcordanceService {
  // In a real app, this would query a dedicated Strong's dictionary table
  // For now, we'll mock the lookup based on the v1 structure
  Future<Map<String, String>> getDefinition(String strongNumber) async {
    // Mock definitions
    final definitions = {
      'H430': 'Elohim (Dieu, dieux, juges)',
      'G2316': 'Theos (Dieu, un être divin)',
      'H7225': 'Reshith (Commencement, prémices)',
    };

    return {
      'number': strongNumber,
      'definition': definitions[strongNumber] ?? 'Définition non trouvée.',
    };
  }
}
