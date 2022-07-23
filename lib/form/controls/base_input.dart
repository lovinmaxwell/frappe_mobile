import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../model/doctype_response.dart';

class ControlInput {
  // Function? setMandatory(
  //   DoctypeField doctypeField,
  // ) {
  //   if (doctypeField.reqd == 1) {
  //     return FormBuilderValidators.required;
  //   } else {
  //     return null;
  //   }
  // }
// A value of type
// 'String? Function(dynamic) Function({String? errorText})'
// can't be returned from the method 'setMandatory'
// because it has a return type of
// 'String? Function(dynamic) Function(BuildContext, {String errorText})?

  Function<T>(BuildContext, {String? errorText})? setMandatory(
    DoctypeField doctypeField,
  ) {
    if (doctypeField.reqd == 1) {
      return required;
    } else {
      return null;
    }
  }

  FormFieldValidator<T> required<T>(
    BuildContext context, {
    String? errorText,
  }) {
    return (T? valueCandidate) {
      if (valueCandidate == null ||
          (valueCandidate is String && valueCandidate.trim().isEmpty) ||
          (valueCandidate is Iterable && valueCandidate.isEmpty) ||
          (valueCandidate is Map && valueCandidate.isEmpty)) {
        return errorText ?? FormBuilderLocalizations.current.requiredErrorText;
      }
      return null;
    };
  }

  bool setBold(DoctypeField doctypeField) {
    if (doctypeField.reqd == 1 || doctypeField.bold == 1) {
      return true;
    } else {
      return false;
    }
  }
}
