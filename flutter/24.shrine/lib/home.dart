// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:shrine/data/gallery_options.dart';
import 'package:shrine/layout/adaptive.dart';
import 'package:shrine/expanding_bottom_sheet.dart';
import 'package:shrine/model/app_state_model.dart';
import 'package:shrine/supplemental/asymmetric_view.dart';
import 'package:scoped_model/scoped_model.dart';

const _ordinalSortKeyName = 'home';

class ProductPage extends StatelessWidget {
  const ProductPage();

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);

    return ScopedModelDescendant<AppStateModel>(
        builder: (context, child, model) {
      return isDesktop
          ? DesktopAsymmetricView(products: model.getProducts())
          : MobileAsymmetricView(products: model.getProducts());
    });
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    this.expandingBottomSheet,
    this.scrim,
    this.backdrop,
    Key key,
  }) : super(key: key);

  final ExpandingBottomSheet expandingBottomSheet;
  final Widget scrim;
  final Widget backdrop;

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);

    // Use sort keys to make sure the cart button is always on the top.
    // This way, a11y users do not have to scroll through the entire list to
    // find the cart, and can easily get to the cart from anywhere on the page.
    return ApplyTextOptions(
      child: Stack(
        children: [
          Semantics(
            container: true,
            child: backdrop,
            sortKey: const OrdinalSortKey(1, name: _ordinalSortKeyName),
          ),
          ExcludeSemantics(child: scrim),
          Align(
            child: Semantics(
              container: true,
              child: expandingBottomSheet,
              sortKey: const OrdinalSortKey(0, name: _ordinalSortKeyName),
            ),
            alignment: isDesktop
                ? AlignmentDirectional.topEnd
                : AlignmentDirectional.bottomEnd,
          ),
        ],
      ),
    );
  }
}
