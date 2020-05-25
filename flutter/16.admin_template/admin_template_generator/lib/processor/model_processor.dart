import 'package:admin_template_annotation/admin_template_annotation.dart';
import 'package:admin_template_generator/misc/type_utils.dart';
import 'package:admin_template_generator/processor/model_field_processor.dart';
import 'package:admin_template_generator/processor/processor.dart';
import 'package:admin_template_generator/value_object/model.dart';
import 'package:admin_template_generator/value_object/model_field.dart';
import 'package:analyzer/dart/element/element.dart';

class ModelProcessor implements Processor<Model> {
  final ClassElement _classElement;

  ModelProcessor(final ClassElement classElement)
      : assert(classElement != null),
        _classElement = classElement;

  @override
  Model process() {
    final name = _classElement.displayName;
    return Model(
      _classElement,
      name,
      _getModelFields(),
    );
  }

  /// Get form fields from model by filtering with Form Annotation
  List<ModelField> _getModelFields() {
    final fields = _classElement.fields
        .where((e) => e.hasAnnotation(AgBase) || e.getter.hasAnnotation(AgBase))
        .map((e) => ModelFieldProcessor(e).process())
        .toList();
    return fields;
  }
}
