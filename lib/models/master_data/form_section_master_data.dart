import 'form_detail_master_data.dart';

class FormSectionMasterData {
  final String? name;
  final List<FormDetailMasterData> items;

  FormSectionMasterData({
    required this.name,
    required this.items,
  });

  factory FormSectionMasterData.fromJson(Map<String, dynamic> json) {
    return FormSectionMasterData(
      name: json['name'], // puede ser null
      items: (json['items'] as List)
          .map((e) => FormDetailMasterData.fromJson(e))
          .toList(),
    );
  }
}