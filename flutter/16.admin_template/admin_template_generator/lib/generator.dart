import 'dart:async';

import 'package:admin_template_annotation/annotations.dart';
import 'package:admin_template_generator/writer/form_writer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

import 'processor/form_processor.dart';

/// A generator that produces the implementation of the form code.
///
/// Note: This supposes to not use Annotation to build edit form.
/// For now annotation is the easiest manner to make a generator.
/// In the future, the generator should lookup the implementors of AgForm instead.
class FormGenerator extends GeneratorForAnnotation<AgEditForm> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    final Element element,
    final ConstantReader annotation,
    final BuildStep buildStep,
  ) {
    final form = _getForm(element);
    final library =
        Library((builder) => builder..body.add(FormWriter(form).write()));

    return library.accept(DartEmitter()).toString();
  }

  Form _getForm(final Element element) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          'The element annotated with @agEditForm is not a class.',
          element: element);
    }

    final classElement = element as ClassElement;
    if (!classElement.isAbstract) {
      throw InvalidGenerationSourceError('The form class has to be abstract',
          element: classElement);
    }

    return FormProcessor(classElement).process();
  }
}