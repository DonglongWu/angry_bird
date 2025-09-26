import 'package:flame_forge2d/flame_forge2d.dart';

class Ground extends BodyComponent {
  final double y;
  Ground({this.y = 18}) : super(renderBody: true);

  @override
  Body createBody() {
    final shape = PolygonShape()..setAsBoxXY(50, 0.5);
    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = Vector2(0, 0);
    final body = world.createBody(bodyDef);
    body.createFixtureFromShape(shape);
    return body;
  }
}
