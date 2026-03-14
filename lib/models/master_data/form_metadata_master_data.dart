import 'form_tab_master_data.dart';
//import '../../models/form_metadata.dart';

class FormMetadataMasterData {
  final String entity;
  final String displayName;
  final String mode;
  final List<FormTabMasterData> tabs;

  FormMetadataMasterData({
    required this.entity,
    required this.displayName,
    required this.mode,
    required this.tabs,
  });

  factory FormMetadataMasterData.fromJson(Map<String, dynamic> json) {
    return FormMetadataMasterData(
      entity: json['entity'],
      displayName: json['displayName'],
      mode: json['mode'],
      tabs: (json['tabs'] as List)
          .map((t) => FormTabMasterData.fromJson(t))
          .toList(),
    );
  }


}