import 'form_section_master_data.dart';
//import '../../models/form_metadata.dart';


class FormTabMasterData {
  final String key;
  final String title;
  final String tabType; // "form" | "list" | "grid"
  final int sortOrder;
  final List<FormSectionMasterData> sections;

  FormTabMasterData({
    required this.key,
    required this.title,
    required this.tabType,
    required this.sortOrder,
    required this.sections,
  });

  factory FormTabMasterData.fromJson(Map<String, dynamic> json) {
    return FormTabMasterData(
      key: json['key'],
      title: json['title'],
      tabType: json['tabType'],
      sortOrder: json['sortOrder'],
      sections: (json['sections'] as List)
          .map((s) => FormSectionMasterData.fromJson(s))
          .toList(),
    );
  }


}