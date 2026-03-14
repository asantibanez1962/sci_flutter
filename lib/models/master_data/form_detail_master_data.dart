class FormDetailMasterData {
  final String detailType;
  final String? sectionName;
  final String? fieldName;
  final String? relatedEntity;
  final String? foreignKey;
  final int sortOrder;
  final String? hint;
  final String? placeholder;
  final String? readOnlyExpression;
  final String? requiredExpression;
  final String? style;
  final String? validators;
  final String? visibleExpression;
  final int? width;

  FormDetailMasterData({
    required this.detailType,
    this.sectionName,
    this.fieldName,
    this.relatedEntity,
    this.foreignKey,
    required this.sortOrder,
    this.hint,
    this.placeholder,
    this.readOnlyExpression,
    this.requiredExpression,
    this.style,
    this.validators,
    this.visibleExpression,
    this.width,
  });

  factory FormDetailMasterData.fromJson(Map<String, dynamic> json) {
    return FormDetailMasterData(
      detailType: json['detailType'],
      sectionName: json['sectionName'],
      fieldName: json['fieldName'],
      relatedEntity: json['relatedEntity'],
      foreignKey: json['foreignKey'],
      sortOrder: json['sortOrder'] ?? 0,
      hint: json['hint'],
      placeholder: json['placeholder'],
      readOnlyExpression: json['readOnlyExpression'],
      requiredExpression: json['requiredExpression'],
      style: json['style'],
      validators: json['validators'],
      visibleExpression: json['visibleExpression'],
      width: json['width'], // puede ser null
    );
  }
}