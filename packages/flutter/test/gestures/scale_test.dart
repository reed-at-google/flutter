// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

import 'gesture_tester.dart';

void main() {
  setUp(ensureGestureBinding);

  testGesture('Should recognize scale gestures', (GestureTester tester) {
    final ScaleGestureRecognizer scale = new ScaleGestureRecognizer();
    final TapGestureRecognizer tap = new TapGestureRecognizer();

    bool didStartScale = false;
    Offset updatedFocalPoint;
    scale.onStart = (ScaleStartDetails details) {
      didStartScale = true;
      updatedFocalPoint = details.focalPoint;
    };

    double updatedScale;
    scale.onUpdate = (ScaleUpdateDetails details) {
      updatedScale = details.scale;
      updatedFocalPoint = details.focalPoint;
    };

    bool didEndScale = false;
    scale.onEnd = (ScaleEndDetails details) {
      didEndScale = true;
    };

    bool didTap = false;
    tap.onTap = () {
      didTap = true;
    };

    final TestPointer pointer1 = new TestPointer(1);

    final PointerDownEvent down = pointer1.down(const Offset(10.0, 10.0));
    scale.addPointer(down);
    tap.addPointer(down);

    tester.closeArena(1);
    expect(didStartScale, isFalse);
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // One-finger panning
    tester.route(down);
    expect(didStartScale, isFalse);
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    tester.route(pointer1.move(const Offset(20.0, 30.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(20.0, 30.0));
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Two-finger scaling
    final TestPointer pointer2 = new TestPointer(2);
    final PointerDownEvent down2 = pointer2.down(const Offset(10.0, 20.0));
    scale.addPointer(down2);
    tap.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);

    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didStartScale, isFalse);

    // Zoom in
    tester.route(pointer2.move(const Offset(0.0, 10.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(10.0, 20.0));
    updatedFocalPoint = null;
    expect(updatedScale, 2.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Zoom out
    tester.route(pointer2.move(const Offset(15.0, 25.0)));
    expect(updatedFocalPoint, const Offset(17.5, 27.5));
    updatedFocalPoint = null;
    expect(updatedScale, 0.5);
    updatedScale = null;
    expect(didTap, isFalse);

    // Three-finger scaling
    final TestPointer pointer3 = new TestPointer(3);
    final PointerDownEvent down3 = pointer3.down(const Offset(25.0, 35.0));
    scale.addPointer(down3);
    tap.addPointer(down3);
    tester.closeArena(3);
    tester.route(down3);

    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didStartScale, isFalse);

    // Zoom in
    tester.route(pointer3.move(const Offset(55.0, 65.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(30.0, 40.0));
    updatedFocalPoint = null;
    expect(updatedScale, 5.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Return to original positions but with different fingers
    tester.route(pointer1.move(const Offset(25.0, 35.0)));
    tester.route(pointer2.move(const Offset(20.0, 30.0)));
    tester.route(pointer3.move(const Offset(15.0, 25.0)));
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, const Offset(20.0, 30.0));
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    tester.route(pointer1.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedScale, isNull);
    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(didTap, isFalse);

    // Continue scaling with two fingers
    tester.route(pointer3.move(const Offset(10.0, 20.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(15.0, 25.0));
    updatedFocalPoint = null;
    expect(updatedScale, 2.0);
    updatedScale = null;

    tester.route(pointer2.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedScale, isNull);
    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(didTap, isFalse);

    // Continue panning with one finger
    tester.route(pointer3.move(const Offset(0.0, 0.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(0.0, 0.0));
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;

    // We are done
    tester.route(pointer3.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedScale, isNull);
    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(didTap, isFalse);

    scale.dispose();
    tap.dispose();
  });

  testGesture('Scale gesture competes with drag', (GestureTester tester) {
    final ScaleGestureRecognizer scale = new ScaleGestureRecognizer();
    final HorizontalDragGestureRecognizer drag = new HorizontalDragGestureRecognizer();

    final List<String> log = <String>[];

    scale.onStart = (ScaleStartDetails details) { log.add('scale-start'); };
    scale.onUpdate = (ScaleUpdateDetails details) { log.add('scale-update'); };
    scale.onEnd = (ScaleEndDetails details) { log.add('scale-end'); };

    drag.onStart = (DragStartDetails details) { log.add('drag-start'); };
    drag.onEnd = (DragEndDetails details) { log.add('drag-end'); };

    final TestPointer pointer1 = new TestPointer(1);

    final PointerDownEvent down = pointer1.down(const Offset(10.0, 10.0));
    scale.addPointer(down);
    drag.addPointer(down);

    tester.closeArena(1);
    expect(log, isEmpty);

    // Vertical moves are scales.
    tester.route(down);
    expect(log, isEmpty);

    tester.route(pointer1.move(const Offset(10.0, 30.0)));
    expect(log, equals(<String>['scale-start', 'scale-update']));
    log.clear();

    final TestPointer pointer2 = new TestPointer(2);
    final PointerDownEvent down2 = pointer2.down(const Offset(10.0, 20.0));
    scale.addPointer(down2);
    drag.addPointer(down2);

    tester.closeArena(2);
    expect(log, isEmpty);

    // Second pointer joins scale even though it moves horizontally.
    tester.route(down2);
    expect(log, <String>['scale-end']);
    log.clear();

    tester.route(pointer2.move(const Offset(30.0, 20.0)));
    expect(log, equals(<String>['scale-start', 'scale-update']));
    log.clear();

    tester.route(pointer1.up());
    expect(log, equals(<String>['scale-end']));
    log.clear();

    tester.route(pointer2.up());
    expect(log, isEmpty);
    log.clear();

    // Horizontal moves are drags.
    final TestPointer pointer3 = new TestPointer(3);
    final PointerDownEvent down3 = pointer3.down(const Offset(30.0, 30.0));
    scale.addPointer(down3);
    drag.addPointer(down3);
    tester.closeArena(3);
    tester.route(down3);

    expect(log, isEmpty);

    tester.route(pointer3.move(const Offset(50.0, 30.0)));
    expect(log, equals(<String>['scale-start', 'scale-update']));
    log.clear();

    tester.route(pointer3.up());
    expect(log, equals(<String>['scale-end']));
    log.clear();

    scale.dispose();
    drag.dispose();
  });
}
