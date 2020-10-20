import 'package:admin_template_generator/output/form_field.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import 'util.dart';

main() {
  useDartfmt();

  group('TextField', () {
    test('has default attributes', () {
      final textField = TextField('name', {});
      expect(textField.toWidgetExpression(), equalsDart(r'''
AgTextField(initialValue: model.name, onSaved: (newValue) { model = model.copyWith(name: newValue); } )'''));
    });
  });
}
