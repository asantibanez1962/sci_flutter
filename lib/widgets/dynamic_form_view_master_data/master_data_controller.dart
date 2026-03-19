import 'package:flutter/material.dart';
import '../dynamic_form_view/dynamic_form_controller.dart';

class MasterDataController extends ChangeNotifier {
  final DynamicFormController formController;

  // Validación por tab
  final Map<String, bool> tabIsValid = {};

  // Errores por tab
  final Map<String, Map<String, String?>> tabErrors = {};

  MasterDataController({required this.formController});

  // ---------------------------------------------
  // VALIDACIÓN GLOBAL
  // ---------------------------------------------
 bool get isValid {
  //print("MasterDataController → formController.hasValidationErrors = ${formController.hasValidationErrorsFor}");
  if (tabIsValid.isEmpty) return false;

  final tabsOk = tabIsValid.values.every((v) => v == true);
  //final formOk = !formController.hasValidationErrors;

  return tabsOk; //&& formOk;
}

  void updateTabValidation(String tabKey, bool isValid) {
    tabIsValid[tabKey] = isValid;
    notifyListeners();
  }

  void updateTabErrors(String tabKey, Map<String, String?> errors) {
    tabErrors[tabKey] = errors;
    notifyListeners();
  }

  // ---------------------------------------------
  // MODIFIED GLOBAL
  // ---------------------------------------------
  bool get hasUnsavedChanges => formController.hasUnsavedChanges;

  // ---------------------------------------------
  // SINCRONIZACIÓN DE VALORES
  // ---------------------------------------------
  void updateValue(String field, dynamic value) {
    formController.updateValue(field, value);
    notifyListeners();
  }

  // ---------------------------------------------
  // SINCRONIZAR TODOS LOS SUBFORMS
  // ---------------------------------------------
  void syncAll() {
    formController.syncControllersToFormData();
    notifyListeners();
  }

  // ---------------------------------------------
  // MODO GLOBAL
  // ---------------------------------------------
  Future<void> startEditing() async {
    await formController.startEditing();
    notifyListeners();
  }

  Future<void> cancelEditing() async {
    await formController.cancelEditing();
    notifyListeners();
  }

  // ---------------------------------------------
  // GUARDAR GLOBAL
  // ---------------------------------------------
  Future<bool> saveMaster() async {
    syncAll();

    final result = await formController.saveToBackend();

    if (result.success) {
      formController.markAllClean();
      notifyListeners();
      return true;
    }

    return false;
  }

  
}