class DocumentInfo {
  final String documentType;
  final String debtor;
  final String creditor;
  final String date;
  final String amount;
  final String notary;
  final String caseNumber;

  const DocumentInfo({
    required this.documentType,
    required this.debtor,
    required this.creditor,
    required this.date,
    required this.amount,
    required this.notary,
    required this.caseNumber,
  });

  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    return DocumentInfo(
      documentType: json['document_type']?.toString() ?? '',
      debtor: json['debtor']?.toString() ?? '',
      creditor: json['creditor']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      notary: json['notary']?.toString() ?? '',
      caseNumber: json['case_number']?.toString() ?? '',
    );
  }

  String get documentTypeDisplay {
    switch (documentType) {
      case 'executive_inscription':
        return 'Исполнительная надпись нотариуса';
      case 'enforcement_order':
        return 'Исполнительный лист';
      default:
        return 'Документ исполнительного производства';
    }
  }
}

class ViolationAnalysis {
  final List<String> notificationViolations;
  final List<String> limitationPeriodViolations;
  final List<String> proceduralViolations;

  const ViolationAnalysis({
    required this.notificationViolations,
    required this.limitationPeriodViolations,
    required this.proceduralViolations,
  });

  factory ViolationAnalysis.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic value) {
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }

    return ViolationAnalysis(
      notificationViolations: parseList(json['notification_violations']),
      limitationPeriodViolations: parseList(json['limitation_period_violations']),
      proceduralViolations: parseList(json['procedural_violations']),
    );
  }

  List<String> get allViolations => [
        ...notificationViolations,
        ...limitationPeriodViolations,
        ...proceduralViolations,
      ];

  bool get hasViolations => allViolations.isNotEmpty;
}

class LegalCase {
  final DocumentInfo documentInfo;
  final ViolationAnalysis violations;
  final String legalAnalysis;
  final String recommendedStrategy;
  final String objectionDraft;

  const LegalCase({
    required this.documentInfo,
    required this.violations,
    required this.legalAnalysis,
    required this.recommendedStrategy,
    required this.objectionDraft,
  });

  factory LegalCase.fromJson(Map<String, dynamic> json) {
    return LegalCase(
      documentInfo: DocumentInfo.fromJson(
          (json['document_info'] as Map<String, dynamic>?) ?? {}),
      violations: ViolationAnalysis.fromJson(
          (json['violations'] as Map<String, dynamic>?) ?? {}),
      legalAnalysis: json['legal_analysis']?.toString() ?? '',
      recommendedStrategy: json['recommended_strategy']?.toString() ?? '',
      objectionDraft: json['objection_draft']?.toString() ?? '',
    );
  }
}
